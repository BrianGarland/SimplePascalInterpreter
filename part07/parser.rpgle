**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h
/INCLUDE headers/parser.rpgle_h



//--------------------------------------
// Parser
//--------------------------------------

DCL-PROC BinOp_Init;
    DCL-PI *N POINTER;
        Left POINTER VALUE;
        Op LIKEDS(Token_t) VALUE;
        Right POINTER VALUE;
    END-PI;

    DCL-DS self LIKEDS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = Left;
    self.token = Op;
    self.right = Right;

    RETURN p_node;

END-PROC;



DCL-PROC Num_Init;
    DCL-PI *N POINTER;
        token LIKEDS(Token_t) VALUE;
    END-PI;

    DCL-DS self LIKEDS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = *NULL;
    self.token = token;
    self.right = *NULL;

    RETURN p_Node;

END-PROC;



DCL-PROC Parser_Init EXPORT;
    DCL-PI *N LIKEDS(Parser_t);
        lexer LIKEDS(Lexer_t);
    END-PI;

    DCL-DS self LIKEDS(Parser_t) INZ(*LIKEDS);

    self.lexer = lexer;
    self.current_token = Lexer_Get_Next_Token(self.lexer);

    RETURN self;

END-PROC;



DCL-PROC Parser_Error;
    DCL-PI *N;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S MsgKey CHAR(4);
    DCL-S MsgDta VARCHAR(100);

    MsgDta = 'Invalid syntax';

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

END-PROC;



DCL-PROC Parser_Eat;
    DCL-PI *N;
        self LIKEDS(Parser_t);
        token_type LIKE(MyString) VALUE;
    END-PI;

    IF self.current_token.type = token_type;
        self.current_token = Lexer_Get_Next_Token(self.lexer);
    ELSE;
        Parser_Error(self);
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Parser_Factor;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS token LIKEDS(Token_t) INZ(*LIKEDS);

    DCL-S node POINTER;

    token = self.current_token;

    IF token.type = INTEGER;
        Parser_Eat(self:INTEGER);
        RETURN Num_Init(token);

    ELSEIF token.type = LPAREN;
        Parser_Eat(self:LPAREN);
        node = Parser_expr(self);
        Parser_Eat(self:RPAREN);
        RETURN node;

    ENDIF;

END-PROC;



DCL-PROC Parser_Term;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS token LIKEDS(token_t) INZ(*LIKEDS);

    DCL-S node POINTER;

    node = Parser_Factor(self);

    DOW self.current_token.type = MUL
        OR self.current_token.type = DIV;

        token = self.current_token;

        IF token.type = MUL;
            Parser_Eat(self:MUL);
        ELSEIF token.type = DIV;
            Parser_Eat(self:DIV);
        ENDIF;

        node = BinOp_init(node:token:parser_factor(self));

    ENDDO;

    RETURN node;

END-PROC;



DCL-PROC Parser_Expr;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS token LIKEDS(Token_t);

    DCL-S node POINTER;

    node = Parser_Term(self);

    DOW self.current_token.type = PLUS
        OR self.current_token.type = MINUS;

        token = self.current_token;

        IF token.type = PLUS;
            Parser_Eat(self:PLUS);
        ELSEIF token.type = MINUS;
            Parser_Eat(self:MINUS);
        ENDIF;

        node = BinOp_init(node:token:parser_term(self));

    ENDDO;


    RETURN node;

END-PROC;



DCL-PROC Parser_Parse EXPORT;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    RETURN Parser_Expr(self);

END-PROC;



