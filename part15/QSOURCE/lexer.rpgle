**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h



//--------------------------------------
// Token
//--------------------------------------

DCL-PROC Token_Init EXPORT;
    DCL-PI *N LIKEDS(Token_t);
        Type   LIKE(ShortString) VALUE;
        Value  LIKE(ShortString) VALUE;
        LineNo UNS(5) VALUE OPTIONS(*NOPASS);
        Column UNS(5) VALUE OPTIONS(*NOPASS);
    END-PI;

    DCL-DS self LIKEDS(Token_t) INZ(*LIKEDS);

    self.type = %TRIM(type);
    self.value = %TRIM(value);
    IF %PARMS >= %PARMNUM(LineNo);
        self.lineno = LineNo;
    ENDIF;
    IF %PARMS >= %PARMNUM(Column);
        self.column = Column;
    ENDIF;

    RETURN self;

END-PROC;



//--------------------------------------
// Lexer
//--------------------------------------

DCL-PROC Lexer_Init EXPORT;
    DCL-PI *N LIKEDS(Lexer_t);
        text LIKE(LongString);
    END-PI;

    DCL-DS Self LIKEDS(Lexer_t) INZ(*LIKEDS);

    RESERVED_KEYWORDS(1).id    = 'PROGRAM';
    RESERVED_KEYWORDS(1).value = 'PROGRAM';
    RESERVED_KEYWORDS(2).id    = 'INTEGER';
    RESERVED_KEYWORDS(2).value = 'INTEGER';
    RESERVED_KEYWORDS(3).id    = 'REAL';
    RESERVED_KEYWORDS(3).value = 'REAL';
    RESERVED_KEYWORDS(4).id    = 'INTEGER_DIV';
    RESERVED_KEYWORDS(4).value = 'DIV';
    RESERVED_KEYWORDS(5).id    = 'VAR';
    RESERVED_KEYWORDS(5).value = 'VAR';
    RESERVED_KEYWORDS(6).id    = 'PROCEDURE';
    RESERVED_KEYWORDS(6).value = 'PROCEDURE';
    RESERVED_KEYWORDS(7).id    = 'BEGIN';
    RESERVED_KEYWORDS(7).value = 'BEGIN';
    RESERVED_KEYWORDS(8).id    = 'END';
    RESERVED_KEYWORDS(8).value = 'END';

    self.text = text;
    self.pos = 1;
    self.current_char = %SUBST(self.text:self.pos:1);

    RETURN self;

END-PROC;



DCL-PROC Lexer_Error;
    DCL-PI *N;
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-S MsgKey CHAR(4);
    DCL-S MsgDta VARCHAR(100);

    MsgDta = 'LEXER: Error on ''' + self.current_char
           + ''' line: ' + %CHAR(self.lineno)
           + ' column: ' + %CHAR(self.column);

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*':1:MsgKey:APIError);

    RETURN;

END-PROC;



DCL-PROC Lexer_Advance;
    DCL-PI *N;
        self LIKEDS(Lexer_t);
    END-PI;

    IF self.current_char = LF;
        self.lineno += 1;
        self.column = 0;
    ENDIF;

    self.pos += 1;
    IF self.pos > %LEN(self.text);
        self.current_char = NONE; // Indicates end of input
    ELSE;
        self.current_char = %SUBST(self.text:self.pos:1);
        self.column += 1;
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Lexer_Peek;
    DCL-PI *N LIKE(ShortString);
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-S Peek_Pos LIKE(self.pos);

    Peek_Pos = self.pos + 1;
    IF Peek_Pos > %LEN(Self.text);
        RETURN NONE;
    ELSE;
        RETURN %SUBST(self.text:Peek_Pos:1);
    ENDIF;
END-PROC;



DCL-PROC Lexer_Skip_Whitespace;
    DCL-PI *N;
        self LIKEDS(Lexer_t);
    END-PI;

    DOW self.current_char <> NONE AND isSpace(self.current_char);
        Lexer_Advance(self);
    ENDDO;

    RETURN;

END-PROC;



DCL-PROC Lexer_Skip_Comment;
    DCL-PI *N;
        self LIKEDS(Lexer_t);
    END-PI;

    DOW self.current_char <> '}';
        Lexer_Advance(self);
    ENDDO;
    Lexer_Advance(self); // The closing curly brace

    RETURN;

END-PROC;



DCL-PROC Lexer_Number;
    DCL-PI *N LIKEDS(Token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-DS Token LIKEDS(Token_t);

    DCL-S result LIKE(ShortString) INZ('');

    DOW self.current_char <> NONE AND isDigit(self.current_char);
        result += self.current_char;
        Lexer_Advance(self);
    ENDDO;

    IF self.current_char = '.';
        result += self.current_char;
        Lexer_Advance(self);
        DOW self.current_char <> NONE AND isDigit(self.current_char);
            result += self.current_char;
            Lexer_Advance(self);
        ENDDO;
        token = Token_Init('REAL_CONST':result:self.lineno:self.column);
    ELSE;
        token = Token_Init('INTEGER_CONST':result:self.lineno:self.column);
    ENDIF;

    RETURN token;

END-PROC;



DCL-PROC Lexer_ID;
    DCL-PI *N LIKEDS(Token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-DS Token LIKEDS(Token_t);

    DCL-S i      UNS(10);
    DCL-S Result LIKE(ShortString) INZ('');

    DOW Self.Current_Char <> NONE AND isAlNum(Self.Current_Char);
        Result += Self.Current_Char;
        Lexer_Advance(Self);
    ENDDO;

    I = %LOOKUP(Result:RESERVED_KEYWORDS(*).id);
    IF i <> 0;
        Token = Token_Init(RESERVED_KEYWORDS(i).value:RESERVED_KEYWORDS(i).value:self.lineno:self.column);
    ELSE;
        Token = Token_Init(ID:Result:self.lineno:self.column);
    ENDIF;

    RETURN Token;

END-PROC;



DCL-PROC Lexer_Get_Next_Token EXPORT;
    DCL-PI *N LIKEDS(token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DOW self.current_char <> NONE;

        SELECT;
        WHEN isSpace(self.current_char);
            Lexer_Skip_Whitespace(self);
            ITER;

        WHEN self.current_char = '{';
            Lexer_Advance(self);
            Lexer_Skip_Comment(self);
            ITER;

        WHEN isAlpha(self.current_char);
            RETURN Lexer_ID(self);

        WHEN isDigit(self.current_char);
            RETURN Lexer_Number(self);

        WHEN self.current_char = ':' AND Lexer_Peek(self) = '=';
            Lexer_Advance(self);
            Lexer_Advance(self);
            RETURN Token_Init(ASSIGN:':=':self.lineno:self.column);

        WHEN self.current_char = ';';
            Lexer_Advance(self);
            RETURN Token_Init(SEMI:';':self.lineno:self.column);

        WHEN self.current_char = ':';
            Lexer_Advance(self);
            RETURN Token_Init(COLON:':':self.lineno:self.column);

        WHEN self.current_char = ',';
            Lexer_Advance(self);
            RETURN Token_Init(COMMA:',':self.lineno:self.column);

        WHEN self.current_char = '+';
            Lexer_Advance(self);
            RETURN Token_Init(PLUS:'+':self.lineno:self.column);

        WHEN self.current_char = '-';
            Lexer_Advance(self);
            RETURN Token_Init(MINUS:'-':self.lineno:self.column);

        WHEN self.current_char = '*';
            Lexer_Advance(self);
            RETURN Token_Init(MUL:'*':self.lineno:self.column);

        WHEN self.current_char = '/';
            Lexer_Advance(self);
            RETURN Token_Init(FLOAT_DIV:'/':self.lineno:self.column);

        WHEN self.current_char = '(';
            Lexer_Advance(self);
            RETURN Token_Init(LPAREN:'(':self.lineno:self.column);

        WHEN self.current_char = ')';
            Lexer_Advance(self);
            RETURN Token_Init(RPAREN:')':self.lineno:self.column);

        WHEN self.current_char = '.';
            Lexer_Advance(self);
            RETURN Token_Init(DOT:'.':self.lineno:self.column);

        OTHER;
            Lexer_Error(self);

        ENDSL;

    ENDDO;

    RETURN Token_Init(EOF:NONE:self.lineno:self.column);

END-PROC;



