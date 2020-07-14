**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h



//--------------------------------------
// Token
//--------------------------------------

DCL-PROC Token_Init EXPORT;
    DCL-PI *N LIKEDS(Token_t);
        Type LIKE(MyString) VALUE;
        Value LIKE(MyString) VALUE;
    END-PI;

    DCL-DS self LIKEDS(Token_t) INZ(*LIKEDS);

    self.type = type;
    self.value = value;

    RETURN self;

END-PROC;



DCL-PROC Token_Str EXPORT;
    DCL-PI *n LIKE(MyString);
        self LIKEDS(Token_t);
    END-PI;

    RETURN 'Token({' + self.type + '}, {' + self.value + '})';

END-PROC;



//--------------------------------------
// Lexer
//--------------------------------------

DCL-PROC Lexer_Init EXPORT;
    DCL-PI *N LIKEDS(Lexer_t);
        text LIKE(MyString);
    END-PI;

    DCL-DS Self LIKEDS(Lexer_t) INZ(*LIKEDS);

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

    MsgDta = 'Invalid character (' + self.current_char
           + ') at ' + %CHAR(self.pos);

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

    RETURN;

END-PROC;



DCL-PROC Lexer_Advance;
    DCL-PI *N;
        self LIKEDS(Lexer_t);
    END-PI;

    self.pos += 1;
    IF self.pos > %LEN(self.text);
        self.current_char = NONE;
    ELSE;
        self.current_char = %SUBST(self.text:self.pos:1);
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Lexer_Peek;
    DCL-PI *N LIKE(MyString);
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

    DOW self.current_char <> NONE AND self.current_char = '';
        Lexer_Advance(self);
    ENDDO;

    RETURN;

END-PROC;



DCL-PROC Lexer_Integer;
    DCL-PI *N LIKE(MyString);
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-S result LIKE(MyString) INZ('');

    DOW self.current_char <> NONE AND %SCAN(self.current_char:digits) > 0;
        result += self.current_char;
        Lexer_Advance(self);
    ENDDO;

    RETURN result;

END-PROC;



DCL-PROC Lexer_ID;
    DCL-PI *N LIKEDS(Token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-DS Token LIKEDS(Token_t);

    DCL-S i      UNS(5);
    DCL-S Result LIKE(MyString) INZ('');

    DOW Self.Current_Char <> NONE AND %SCAN(Self.Current_Char:alnum) > 0;
        Result += Self.Current_Char;
        Lexer_Advance(Self);
    ENDDO;

    I = %LOOKUP(Result:RESERVED_KEYWORDS);
    IF i <> 0;
        Token = Token_Init(RESERVED_KEYWORDS(i):RESERVED_KEYWORDS(i));
    ELSE;
        Token = Token_Init(ID:Result);
    ENDIF;

    RETURN Token;

END-PROC;



DCL-PROC Lexer_Get_Next_Token EXPORT;
    DCL-PI *N LIKEDS(token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DOW self.current_char <> NONE;

        SELECT;
        WHEN self.current_char = '';
            Lexer_Skip_Whitespace(self);
            ITER;

        WHEN %SCAN(self.current_char:alpha) > 0;
            RETURN Lexer_ID(self);

        WHEN %SCAN(self.current_char:digits) > 0;
            RETURN Token_Init(INTEGER:Lexer_Integer(self));

        WHEN self.current_char = ':' AND Lexer_Peek(self) = '=';
            Lexer_Advance(self);
            Lexer_Advance(self);
            RETURN Token_Init(ASSIGN:':=');

        WHEN self.current_char = ';';
            Lexer_Advance(self);
            RETURN Token_Init(SEMI:';');

        WHEN self.current_char = '+';
            Lexer_Advance(self);
            RETURN Token_Init(PLUS:'+');

        WHEN self.current_char = '-';
            Lexer_Advance(self);
            RETURN Token_Init(MINUS:'-');

        WHEN self.current_char = '*';
            Lexer_Advance(self);
            RETURN Token_Init(MUL:'*');

        WHEN self.current_char = '/';
            Lexer_Advance(self);
            RETURN Token_Init(DIV:'/');

        WHEN self.current_char = '(';
            Lexer_Advance(self);
            RETURN Token_Init(LPAREN:'(');

        WHEN self.current_char = ')';
            Lexer_Advance(self);
            RETURN Token_Init(RPAREN:')');

        WHEN self.current_char = '.';
            Lexer_Advance(self);
            RETURN Token_Init(DOT:'.');

        OTHER;
            Lexer_Error(self);

        ENDSL;

    ENDDO;

    RETURN Token_Init(EOF:NONE);

END-PROC;



