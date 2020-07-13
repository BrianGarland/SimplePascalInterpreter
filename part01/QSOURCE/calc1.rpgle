**FREE

DCL-C INTEGER 'INTEGER';
DCL-C PLUS 'PLUS';
DCL-C EOF 'EOF';

DCL-C NONE x'FF';

DCL-C DIGITS '0123456789';
DCL-C FALSE '0';
DCL-C TRUE '1';

DCL-S MyString VARCHAR(30);

DCL-DS Token_t QUALIFIED TEMPLATE;
    type   LIKE(MyString) INZ('');
    value  LIKE(MyString) INZ('');
END-DS;

DCL-DS Interpreter_t QUALIFIED TEMPLATE;
    text          LIKE(MyString) INZ('');
    pos           UNS(5) INZ(1);
    current_token LIKEDS(Token_t) INZ(*LIKEDS);
END-DS;



Main();
*INLR = TRUE;
RETURN;


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



DCL-PROC Interpreter_New;
    DCL-PI *N LIKEDS(Interpreter_t);
        text LIKE(MyString);
    END-PI;

    DCL-DS Self LIKEDS(Interpreter_t) INZ(*LIKEDS);

    self.text = text;
    self.pos = 1;
    self.current_token = Token_New(NONE:NONE);

    RETURN self;

END-PROC;



DCL-PROC Interpreter_Error;
    DCL-PI *N;
        self LIKEDS(Interpreter_t);
    END-PI;

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

    DCL-S MsgKey CHAR(4);
    DCL-S MsgDta VARCHAR(100);

    MsgDta = 'Error parsing input';

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

END-PROC;



DCL-PROC Interpreter_Get_Next_Token;
    DCL-PI *N LIKEDS(token_t);
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-DS aToken LIKEDS(token_t);

    DCL-S current_char LIKE(MyString);
    DCL-S text LIKE(MyString);

    text = self.text;

    IF self.pos > %LEN(text);
        RETURN Token_New(EOF:NONE);
    ENDIF;

    current_char = %SUBST(text:self.pos:1);

    IF %SCAN(current_char:digits) > 0;
        aToken = Token_New(INTEGER:current_char);
        self.pos += 1;
        RETURN aToken;
    ENDIF;

    IF current_char = '+';
        aToken = Token_New(PLUS:current_char);
        self.pos += 1;
        RETURN aToken;
    ENDIF;

    Interpreter_Error(Self);

END-PROC;



DCL-PROC Interpreter_Eat;
    DCL-PI *N;
        self LIKEDS(Interpreter_t);
        token_type LIKE(MyString) VALUE;
    END-PI;

    IF self.current_token.type = token_type;
        self.current_token = Interpreter_Get_Next_Token(self);
    ELSE;
        Interpreter_Error(self);
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Interpreter_Expr;
    DCL-PI *N LIKE(MyString);
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-DS left  LIKEDS(Token_t);
    DCL-DS op    LIKEDS(Token_t);
    DCL-DS right LIKEDS(Token_t);

    DCL-S result INT(10);

    self.current_token = Interpreter_Get_Next_Token(self);

    left = self.current_token;
    Interpreter_Eat(self:INTEGER);

    op = self.current_token;
    Interpreter_Eat(self:PLUS);

    right = self.current_token;
    Interpreter_Eat(self:INTEGER);

    result = %INT(left.value) + %INT(right.value);

    RETURN %CHAR(result);

END-PROC;



DCL-PROC Main;
    DCL-PI *N;
    END-PI;

    DCL-DS interpreter LIKEDS(Interpreter_t) INZ(*LIKEDS);

    DCL-S result LIKE(MyString);
    DCL-S text LIKE(MyString);

    DOU text = '';
        text = '';
        DSPLY 'calc> ' '' text;
        IF text <> '';
            interpreter = Interpreter_New(text);
            result = Interpreter_expr(interpreter);
            DSPLY result;
        ENDIF;
    ENDDO;

    RETURN;

END-PROC;
