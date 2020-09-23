**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h

DCL-DS TOKEN_TYPES QUALIFIED DIM(30);
    id    LIKE(ShortString);
    value LIKE(ShortString);
END-DS;
DCL-S NUM_TOKENS UNS(5) INZ(0);

DCL-DS RESERVED_KEYWORDS QUALIFIED DIM(8);
    id    LIKE(ShortString);
    value LIKE(ShortString);
END-DS;
DCL-S NUM_KEYWORDS UNS(5) INZ(0);



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
    i = %LOOKUP(TokenValue:TOKEN_TYPES(*).id:1:NUM_TOKENS);
    IF i <> 0;
        RETURN TOKEN_TYPES(i).id;
    ENDIF;

    // Not and ID so look for a value
    i = %LOOKUP(TokenValue:TOKEN_TYPES(*).value:1:NUM_TOKENS);
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

    i = %LOOKUP(TokenId:TOKEN_TYPES(*).id:1:NUM_TOKENS);
    IF i <> 0;
        RETURN TOKEN_TYPES(i).value;
    ELSE;
        RETURN NULL;
    ENDIF;

END-PROC;



DCL-PROC IsReservedKeyword;
DCL-PI *N IND;
     token LIKE(ShortString) CONST;
     id    LIKE(ShortString);
END-PI;

    DCL-S i UNS(5);
    DCL-S uppercase LIKE(ShortString);

    uppercase = toUpper(token);

    i = %LOOKUP(uppercase:RESERVED_KEYWORDS(*).value:1:NUM_KEYWORDS);
    IF i <> 0;
        id = RESERVED_KEYWORDS(i).id;
        RETURN TRUE;
    ELSE;
        id = '';
        RETURN FALSE;
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

    DCL-S i UNS(5) INZ(0);
    DCL-S j UNS(5) INZ(0);
    DCL-S ynReserved IND INZ(FALSE);



    // Single-character token types
    i += 1;
    TOKEN_TYPES(i).id    = 'PLUS';
    TOKEN_TYPES(i).value = '+';
    i += 1;
    TOKEN_TYPES(i).id    = 'MINUS';
    TOKEN_TYPES(i).value = '-';
    i += 1;
    TOKEN_TYPES(i).id    = 'MUL';
    TOKEN_TYPES(i).value = '*';
    i += 1;
    TOKEN_TYPES(i).id    = 'FLOAT_DIV';
    TOKEN_TYPES(i).value = '/';
    i += 1;
    TOKEN_TYPES(i).id    = 'LPAREN';
    TOKEN_TYPES(i).value = '(';
    i += 1;
    TOKEN_TYPES(i).id    = 'RPAREN';
    TOKEN_TYPES(i).value = ')';
    i += 1;
    TOKEN_TYPES(i).id    = 'SEMI';
    TOKEN_TYPES(i).value = ';';
    i += 1;
    TOKEN_TYPES(i).id    = 'DOT';
    TOKEN_TYPES(i).value = '.';
    i += 1;
    TOKEN_TYPES(i).id    = 'COLON';
    TOKEN_TYPES(i).value = ':';
    i += 1;
    TOKEN_TYPES(i).id    = 'COMMA';
    TOKEN_TYPES(i).value = ',';

    // Block of reserved keywords
    i += 1;
    TOKEN_TYPES(i).id    = 'PROGRAM';
    TOKEN_TYPES(i).value = 'PROGRAM';
    i += 1;
    TOKEN_TYPES(i).id    = 'INTEGER';
    TOKEN_TYPES(i).value = 'INTEGER';
    i += 1;
    TOKEN_TYPES(i).id    = 'REAL';
    TOKEN_TYPES(i).value = 'REAL';
    i += 1;
    TOKEN_TYPES(i).id    = 'INTEGER_DIV';
    TOKEN_TYPES(i).value = 'DIV';
    i += 1;
    TOKEN_TYPES(i).id    = 'VAR';
    TOKEN_TYPES(i).value = 'VAR';
    i += 1;
    TOKEN_TYPES(i).id    = 'PROCEDURE';
    TOKEN_TYPES(i).value = 'PROCEDURE';
    i += 1;
    TOKEN_TYPES(i).id    = 'BEGIN';
    TOKEN_TYPES(i).value = 'BEGIN';
    i += 1;
    TOKEN_TYPES(i).id    = 'END';
    TOKEN_TYPES(i).value = 'END';

    // Misc.
    i += 1;
    TOKEN_TYPES(i).id    = 'ID';
    TOKEN_TYPES(i).value = 'ID';
    i += 1;
    TOKEN_TYPES(i).id    = 'INTEGER_CONST';
    TOKEN_TYPES(i).value = 'INTEGER_CONST';
    i += 1;
    TOKEN_TYPES(i).id    = 'REAL_CONST';
    TOKEN_TYPES(i).value = 'REAL_CONST';
    i += 1;
    TOKEN_TYPES(i).id    = 'ASSIGN';
    TOKEN_TYPES(i).value = ':=';
    i += 1;
    TOKEN_TYPES(i).id    = 'EOF';
    TOKEN_TYPES(i).value = 'EOF';
    i += 1;
    TOKEN_TYPES(i).id    = 'CHILDREN';
    TOKEN_TYPES(i).value = 'CHILDREN';
    i += 1;
    TOKEN_TYPES(i).id    = 'NOOP';
    TOKEN_TYPES(i).value = 'NOOP';
    i += 1;
    TOKEN_TYPES(i).id    = 'BLOCK';
    TOKEN_TYPES(i).value = 'BLOCK';
    i += 1;
    TOKEN_TYPES(i).id    = 'TYPE';
    TOKEN_TYPES(i).value = 'TYPE';
    i += 1;
    TOKEN_TYPES(i).id    = 'VARDECL';
    TOKEN_TYPES(i).value = 'VARDECL';
    i += 1;
    TOKEN_TYPES(i).id    = 'PARAM';
    TOKEN_TYPES(i).value = 'PARAM';
    i += 1;
    TOKEN_TYPES(i).id    = 'NONE';
    TOKEN_TYPES(i).value = x'FF';

    NUM_TOKENS = i;



    // Extract reserved keywords from token list
    FOR i = 1 TO NUM_TOKENS;
        IF TOKEN_TYPES(i).id = 'PROGRAM';
            ynReserved = TRUE;
        ENDIF;
        IF ynReserved;
            j += 1;
            RESERVED_KEYWORDS(j) = TOKEN_TYPES(i);
        ENDIF;
        IF TOKEN_TYPES(i).id = 'END';
            ynReserved = FALSE;
            LEAVE;
        ENDIF;
    ENDFOR;

    NUM_KEYWORDS = j;



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

    DCL-S Keyword LIKE(ShortString) INZ('');
    DCL-S Result  LIKE(ShortString) INZ('');

    DOW Self.Current_Char <> TokenTypeValue('NONE') AND isAlNum(Self.Current_Char);
        Result += Self.Current_Char;
        Lexer_Advance(Self);
    ENDDO;

    IF IsReservedKeyword(Result:Keyword);
        Token = Token_Init(Keyword:Result:self.lineno:self.column);
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

