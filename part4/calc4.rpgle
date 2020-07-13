**FREE

DCL-C INTEGER 'INTEGER';
DCL-C MUL 'MUL';
DCL-C DIV 'DIV';
DCL-C EOF 'EOF';

DCL-C NONE x'FF';

DCL-C DIGITS '0123456789';
DCL-C FALSE '0';
DCL-C TRUE '1';

DCL-PR QMHSNDPM EXTPGM('QMHSNDPM');
    MessageID  CHAR(7) CONST;
    QualMsgF   CHAR(20) CONST;
    MsgData    CHAR(32767) CONST OPTIONS(*VARSIZE);
    MsgDtaLen  INT(10) CONST;
    MsgType    CHAR(10) CONST;
    CallStkEnt CHAR(10) CONST;
    CallStkCnt INT(10) CONST;
    MessageKey CHAR(4);
    ErrorCode  CHAR(8192) OPTIONS(*VARSIZE);
END-PR;

DCL-DS ErrorCode QUALIFIED;
    BytesProv  INT(10);
    BytesAvail INT(10);
END-DS;

DCL-S MyString VARCHAR(46); // 46 is the longest we can have using DSPLY




//--------------------------------------
// Token
//--------------------------------------

DCL-DS Token_t QUALIFIED TEMPLATE;
    type   LIKE(MyString) INZ('');
    value  LIKE(MyString) INZ('');
END-DS;

//--------------------------------------
// Lexer
//--------------------------------------

DCL-DS Lexer_t QUALIFIED TEMPLATE;
    text          LIKE(MyString) INZ('');
    pos           UNS(5) INZ(1);
    current_char  LIKE(MyString) INZ('');
END-DS;

//--------------------------------------
// Interpreter
//--------------------------------------

DCL-DS Interpreter_t QUALIFIED TEMPLATE;
    lexer LIKEDS(Lexer_t) INZ(*LIKEDS);
    current_token LIKEDS(Token_t) INZ(*LIKEDS);
END-DS;



Main();
*INLR = TRUE;
RETURN;


//--------------------------------------
// Token
//--------------------------------------

DCL-PROC Token_New;
    DCL-PI *N LIKEDS(Token_t);
        type LIKE(MyString) VALUE;
        Value LIKE(MyString) VALUE;
    END-PI;

    DCL-DS self LIKEDS(Token_t) INZ(*LIKEDS);

    self.type = type;
    self.value = value;

    RETURN self;
END-PROC;



DCL-PROC Token_Str;
    DCL-PI *n LIKE(MyString);
        self LIKEDS(Token_t);
    END-PI;

    RETURN 'Token({' + self.type + '}, {' + self.value + '})';

END-PROC;



//--------------------------------------
// Lexer
//--------------------------------------

DCL-PROC Lexer_New;
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

    MsgDta = 'Invalid character';

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

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



DCL-PROC Lexer_Get_Next_Token;
    DCL-PI *N LIKEDS(token_t);
        self LIKEDS(Lexer_t);
    END-PI;

    DOW self.current_char <> NONE;

        SELECT;
        WHEN self.current_char = '';
            Lexer_Skip_Whitespace(self);
            ITER;

        WHEN %SCAN(self.current_char:digits) > 0;
            RETURN Token_New(INTEGER:Lexer_Integer(self));

        WHEN self.current_char = '*';
            Lexer_Advance(self);
            RETURN Token_New(MUL:'*');

        WHEN self.current_char = '/';
            Lexer_Advance(self);
            RETURN Token_New(DIV:'/');

        OTHER;
            Lexer_Error(self);

        ENDSL;

    ENDDO;

    RETURN Token_New(EOF:NONE);

END-PROC;



//--------------------------------------
// Interpreter
//--------------------------------------

DCL-PROC Interpreter_New;
    DCL-PI *N LIKEDS(Interpreter_t);
        lexer LIKEDS(Lexer_t);
    END-PI;

    DCL-DS self LIKEDS(Interpreter_t) INZ(*LIKEDS);

    self.lexer = lexer;
    self.current_token = Lexer_Get_Next_Token(self.lexer);

    RETURN self;

END-PROC;



DCL-PROC Interpreter_Error;
    DCL-PI *N;
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-S MsgKey CHAR(4);
    DCL-S MsgDta VARCHAR(100);

    MsgDta = 'Invalid syntax';

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

END-PROC;



DCL-PROC Interpreter_Eat;
    DCL-PI *N;
        self LIKEDS(Interpreter_t);
        token_type LIKE(MyString) VALUE;
    END-PI;

    IF self.current_token.type = token_type;
        self.current_token = Lexer_Get_Next_Token(self.lexer);
    ELSE;
        Interpreter_Error(self);
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Interpreter_Factor;
    DCL-PI *N LIKE(MyString);
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-DS aToken LIKEDS(Token_t) INZ(*LIKEDS);

    aToken = self.current_token;
    Interpreter_Eat(self:INTEGER);

    RETURN aToken.value;

END-PROC;



DCL-PROC Interpreter_Expr;
    DCL-PI *N LIKE(MyString);
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-DS aToken LIKEDS(Token_t);

    DCL-S result INT(10);

    result = %INT(Interpreter_Factor(self));

    DOW self.current_token.type = MUL
        OR self.current_token.type = DIV;

        aToken = self.current_token;

        IF aToken.type = MUL;
            Interpreter_Eat(self:MUL);
            Result *= %INT(Interpreter_Factor(self));
        ELSEIF aToken.type = DIV;
            Interpreter_Eat(self:DIV);
            Result /= %INT(Interpreter_Factor(self));
        ENDIF;

    ENDDO;

    RETURN %CHAR(result);

END-PROC;



//--------------------------------------
// Main
//--------------------------------------
DCL-PROC Main;
    DCL-PI *N;
    END-PI;

    DCL-DS interpreter LIKEDS(Interpreter_t) INZ(*LIKEDS);
    DCL-DS lexer LIKEDS(Lexer_t) INZ(*LIKEDS);

    DCL-S result LIKE(MyString);
    DCL-S text LIKE(MyString);

    DOU text = '';
        text = '';
        DSPLY 'calc> ' '' text;
        IF text = '';
            LEAVE;
        ENDIF;

        lexer = Lexer_New(text);
        interpreter = Interpreter_New(lexer);
        result = Interpreter_expr(interpreter);
        DSPLY result;

    ENDDO;

    RETURN;

END-PROC;
