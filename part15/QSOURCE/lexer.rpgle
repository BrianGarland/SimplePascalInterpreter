**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h

DCL-DS TOKEN_TYPES QUALIFIED DIM(30);
    id    LIKE(ShortString);
    value LIKE(ShortString);
END-DS;


DCL-DS RESERVED_KEYWORDS QUALIFIED DIM(8);
    id    LIKE(ShortString);
    value LIKE(ShortString);
END-DS;



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



DCL-PROC TokenTypeID EXPORT;
DCL-PI *N LIKE(ShortString);
     TokenValue LIKE(ShortString) CONST;
END-PI;

    DCL-S i UNS(5);

    // If an ID was passed in, return it
    i = %LOOKUP(TokenValue:TOKEN_TYPES(*).id);
    IF i <> 0;
        RETURN TOKEN_TYPES(i).id;
    ENDIF;

    // Not and ID so look for a value
    i = %LOOKUP(TokenValue:TOKEN_TYPES(*).value);
    IF i <> 0;
        RETURN TOKEN_TYPES(i).id;
    ELSE;
        RETURN NULL;
    ENDIF;

END-PROC;



DCL-PROC TokenTypeValue EXPORT;
DCL-PI *N LIKE(ShortString);
     TokenId LIKE(ShortString) CONST;
END-PI;

    DCL-S i UNS(5);

    i = %LOOKUP(TokenId:TOKEN_TYPES(*).id);
    IF i <> 0;
        RETURN TOKEN_TYPES(i).value;
    ELSE;
        RETURN NULL;
    ENDIF;

END-PROC;



//--------------------------------------
// Lexer
//--------------------------------------

DCL-PROC Lexer_Init EXPORT;
    DCL-PI *N LIKEDS(Lexer_t);
        text LIKE(LongString);
    END-PI;

    DCL-DS Self LIKEDS(Lexer_t) INZ(*LIKEDS);

    // Single-character token types
    TOKEN_TYPES(01).id    = 'PLUS';
    TOKEN_TYPES(01).value = '+';
    TOKEN_TYPES(02).id    = 'MINUS';
    TOKEN_TYPES(02).value = '-';
    TOKEN_TYPES(03).id    = 'MUL';
    TOKEN_TYPES(03).value = '*';
    TOKEN_TYPES(04).id    = 'FLOAT_DIV';
    TOKEN_TYPES(04).value = '/';
    TOKEN_TYPES(05).id    = 'LPAREN';
    TOKEN_TYPES(05).value = '(';
    TOKEN_TYPES(06).id    = 'RPAREN';
    TOKEN_TYPES(06).value = ')';
    TOKEN_TYPES(07).id    = 'SEMI';
    TOKEN_TYPES(07).value = ';';
    TOKEN_TYPES(08).id    = 'DOT';
    TOKEN_TYPES(08).value = '.';
    TOKEN_TYPES(09).id    = 'COLON';
    TOKEN_TYPES(09).value = ':';
    TOKEN_TYPES(10).id    = 'COMMA';
    TOKEN_TYPES(10).value = ',';

    // Block of reserved keywords
    TOKEN_TYPES(11).id    = 'PROGRAM';
    TOKEN_TYPES(11).value = 'PROGRAM';
    TOKEN_TYPES(12).id    = 'INTEGER';
    TOKEN_TYPES(12).value = 'INTEGER';
    TOKEN_TYPES(13).id    = 'REAL';
    TOKEN_TYPES(13).value = 'REAL';
    TOKEN_TYPES(14).id    = 'INTEGER_DIV';
    TOKEN_TYPES(14).value = 'DIV';
    TOKEN_TYPES(15).id    = 'VAR';
    TOKEN_TYPES(15).value = 'VAR';
    TOKEN_TYPES(16).id    = 'PROCEDURE';
    TOKEN_TYPES(16).value = 'PROCEDURE';
    TOKEN_TYPES(17).id    = 'BEGIN';
    TOKEN_TYPES(17).value = 'BEGIN';
    TOKEN_TYPES(18).id    = 'END';
    TOKEN_TYPES(18).value = 'END';
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

    // Misc.
    TOKEN_TYPES(19).id    = 'ID';
    TOKEN_TYPES(19).value = 'ID';
    TOKEN_TYPES(20).id    = 'INTEGER_CONST';
    TOKEN_TYPES(20).value = 'INTEGER_CONST';
    TOKEN_TYPES(21).id    = 'REAL_CONST';
    TOKEN_TYPES(21).value = 'REAL_CONST';
    TOKEN_TYPES(22).id    = 'ASSIGN';
    TOKEN_TYPES(22).value = ':=';
    TOKEN_TYPES(23).id    = 'EOF';
    TOKEN_TYPES(23).value = 'EOF';
    TOKEN_TYPES(24).id    = 'CHILDREN';
    TOKEN_TYPES(24).value = 'CHILDREN';
    TOKEN_TYPES(25).id    = 'NOOP';
    TOKEN_TYPES(25).value = 'NOOP';
    TOKEN_TYPES(26).id    = 'BLOCK';
    TOKEN_TYPES(26).value = 'BLOCK';
    TOKEN_TYPES(27).id    = 'TYPE';
    TOKEN_TYPES(27).value = 'TYPE';
    TOKEN_TYPES(28).id    = 'VARDECL';
    TOKEN_TYPES(28).value = 'VARDECL';
    TOKEN_TYPES(29).id    = 'PARAM';
    TOKEN_TYPES(29).value = 'PARAM';
    TOKEN_TYPES(30).id    = 'NONE';
    TOKEN_TYPES(30).value = x'FF';

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
        self.current_char = TokenTypeValue('NONE'); // Indicates end of input
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
        RETURN TokenTypeValue('NONE');
    ELSE;
        RETURN %SUBST(self.text:Peek_Pos:1);
    ENDIF;
END-PROC;



DCL-PROC Lexer_Skip_Whitespace;
    DCL-PI *N;
        self LIKEDS(Lexer_t);
    END-PI;

    DOW self.current_char <> TokenTypeValue('NONE') AND isSpace(self.current_char);
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

    DOW self.current_char <> TokenTypeValue('NONE') AND isDigit(self.current_char);
        result += self.current_char;
        Lexer_Advance(self);
    ENDDO;

    IF self.current_char = '.';
        result += self.current_char;
        Lexer_Advance(self);
        DOW self.current_char <> TokenTypeValue('NONE') AND isDigit(self.current_char);
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

    DOW Self.Current_Char <> TokenTypeValue('NONE') AND isAlNum(Self.Current_Char);
        Result += Self.Current_Char;
        Lexer_Advance(Self);
    ENDDO;

    I = %LOOKUP(Result:RESERVED_KEYWORDS(*).id);
    IF i <> 0;
        Token = Token_Init(RESERVED_KEYWORDS(i).value:RESERVED_KEYWORDS(i).value:self.lineno:self.column);
    ELSE;
        Token = Token_Init(TokenTypeID('ID'):Result:self.lineno:self.column);
    ENDIF;

    RETURN Token;

END-PROC;



DCL-PROC Lexer_Get_Next_Token EXPORT;
    DCL-PI *N LIKEDS(token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DCL-DS SingleCharToken LIKEDS(Lexer_t);

    DOW self.current_char <> TokenTypeValue('NONE');

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
            RETURN Token_Init(TokenTypeID(':='):':=':self.lineno:self.column);

        OTHER;
            // Generic logic for any single character type
            IF TokenTypeID(self.current_char) <> '';
                // Need to save a copy so it is not affected by Lexer_Advance()
                SingleCharToken = self;
                Lexer_Advance(self);
                RETURN Token_Init(TokenTypeID(SingleCharToken.current_char):SingleCharToken.current_char:
                                  SingleCharToken.lineno:SingleCharToken.column);
            ELSE;
                Lexer_Error(self);
            ENDIF;

        ENDSL;

    ENDDO;

    RETURN Token_Init(TokenTypeID('EOF'):'EOF':self.lineno:self.column);

END-PROC;

