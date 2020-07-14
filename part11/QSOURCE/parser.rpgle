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



DCL-PROC UnaryOp_Init;
    DCL-PI *N POINTER;
        op LIKEDS(Token_t) VALUE;
        expr POINTER VALUE;
    END-PI;

    DCL-DS self LIKEDS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = *NULL;
    self.token = op;
    self.right = expr;

    RETURN p_Node;

END-PROC;


DCL-PROC Compound_Init;
    DCL-PI *N POINTER;
    END-PI;

    DCL-DS self LIKEDS(Node_t) BASED(p_Node);

    DCL-DS Child LIKEDS(Child_t) BASED(p_Children);
    DCL-S x UNS(10);

    x = %SIZE(Child_t);
    p_Children = %ALLOC(x);
    p_Node = %ALLOC(%SIZE(Node_t));

    Child.NumChildren = 0;

    self.left = *NULL;
    self.token = Token_Init(CHILDREN:CHILDREN);
    self.right = p_Children;

    RETURN p_Node;

END-PROC;


DCL-PROC Assign_Init;
    DCL-PI *N POINTER;
        Left POINTER VALUE;
        Op LIKEDS(Token_t) VALUE;
        Right POINTER VALUE;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = Left;
    self.token = Op;
    self.right = Right;

    RETURN p_Node;

END-PROC;



DCL-PROC Var_Init;
    DCL-PI *N POINTER;
        token LIKEDS(Token_t) VALUE;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = *NULL;
    self.token = token;
    self.right = *NULL;

    RETURN p_Node;

END-PROC;



DCL-PROC NoOp_Init;
    DCL-PI *N POINTER;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = *NULL;
    self.token = Token_Init(NOOP:' ');
    self.right = *NULL;

    RETURN p_Node;

END-PROC;



DCL-PROC Program_Init;
    DCL-PI *N POINTER;
        Name LIKE(ShortString);
        Block POINTER;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = *NULL;
    self.token = Token_Init(PROGRAM:Name);
    self.right = Block;

    RETURN p_Node;

END-PROC;



DCL-PROC Block_Init;
    DCL-PI *N POINTER;
        Declarations POINTER;
        Compound_Statement POINTER;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = Declarations;
    self.token = Token_Init(BLOCK:'');
    self.right = Compound_Statement;

    RETURN p_Node;

END-PROC;



DCL-PROC VarDecl_Init;
    DCL-PI *N POINTER;
        Var_Node POINTER;
        Type_Node POINTER;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = Var_Node;
    self.token = Token_Init(VARDECL:'');
    self.right = Type_Node;

    RETURN p_Node;

END-PROC;



DCL-PROC Type_Init;
    DCL-PI *N POINTER;
        token LIKEDS(Token_t) VALUE;
    END-PI;

    DCL-DS self LIKEdS(Node_t) BASED(p_Node);

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

    MsgDta = 'PARSER: Invalid syntax: ' + self.current_token.type
           + ' ' + self.current_token.value;

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

END-PROC;



DCL-PROC Parser_Eat;
    DCL-PI *N;
        self LIKEDS(Parser_t);
        token_type LIKE(ShortString) VALUE;
    END-PI;

    IF self.current_token.type = token_type;
        self.current_token = Lexer_Get_Next_Token(self.lexer);
    ELSE;
        Parser_Error(self);
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Parser_Program;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS Var_Node LIKEDS(node_t) BASED(var_p);

    DCL-S Block_Node POINTER;
    DCL-S Program_Node POINTER;
    DCL-S Prog_Name LIKE(ShortString);

    Parser_Eat(self:PROGRAM);
    var_p = Parser_Variable(self);
    Prog_Name = Var_Node.Token.value;
    Parser_Eat(self:SEMI);

    Block_Node = Parser_Block(self);
    Program_Node = Program_Init(Prog_Name:Block_Node);
    Parser_Eat(self:DOT);

    RETURN Program_Node;

END-PROC;



DCL-PROC Parser_Block;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S Declaration_Nodes POINTER;
    DCL-S Compound_Statement_Node POINTER;

    Declaration_Nodes = Parser_Declarations(self);
    Compound_Statement_Node = Parser_Compound_Statement(self);
    RETURN Block_Init(Declaration_Nodes:Compound_Statement_Node);

END-PROC;




DCL-PROC Parser_Declarations;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS Var_Declarations LIKEDS(node_t) DIM(MAX_STATEMENTS)
                            BASED(Var_Declarations_p);
    DCL-DS Var_Declarations2 LIKEDS(node_t) DIM(MAX_STATEMENTS)
                             BASED(Var_Declarations2_p);

    DCL-S I UNS(10) INZ(0);
    DCL-S J UNS(10);

    var_declarations2_p = %ALLOC(%SIZE(node_t) * MAX_STATEMENTS);

    IF self.current_token.type = VAR;
        Parser_Eat(self:VAR);
        DOW self.current_token.type = ID;
            var_declarations_p = Parser_Variable_Declaration(self);
            FOR j = 1 TO MAX_STATEMENTS;
                IF var_Declarations(j).Token.Type = *BLANKS;
                    LEAVE;
                ENDIF;
                i += 1;
                Var_Declarations2(i) = var_Declarations(j);
            ENDFOR;
            Parser_Eat(self:SEMI);
        ENDDO;
    ENDIF;

    RETURN Var_Declarations2_p;

END-PROC;



DCL-PROC Parser_Variable_Declaration;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS Var_Declarations LIKEDS(node_t) DIM(MAX_STATEMENTS)
                            BASED(Var_Declarations_p);

    DCL-DS node LIKEDS(node_t) BASED(p_node);
    DCL-S Var_Nodes POINTER DIM(MAX_STATEMENTS);
    DCL-S I INT(10) INZ(1);
    DCL-S J INT(10) INZ(1);
    DCL-S Type_Node POINTER;

    var_declarations_p = %ALLOC(%SIZE(node_t) * MAX_STATEMENTS);

    var_nodes(i) = Var_Init(self.current_token);
    Parser_Eat(self:ID);

    DOW self.current_token.type = COMMA;
        Parser_Eat(self:COMMA);
        i += 1;
        var_nodes(i) = Var_Init(self.current_Token);
        Parser_Eat(self:ID);
    ENDDO;

    Parser_Eat(self:COLON);

    type_node = Parser_Type_Spec(self);

    FOR j = 1 TO i;
        p_node = VarDecl_Init(var_nodes(j):Type_Node);
        var_declarations(j) = node;
    ENDFOR;

    RETURN var_declarations_p;

END-PROC;



DCL-PROC Parser_Type_Spec;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS Token LIKEDS(Token_t);
    DCL-S Node POINTER;

    Token = self.current_token;

    IF self.current_token.type = INTEGER;
        Parser_Eat(self:INTEGER);
    ELSE;
        Parser_Eat(self:REAL);
    ENDIF;

    Node = Type_Init(Token);

    RETURN Node;

END-PROC;



DCL-PROC Parser_Compound_Statement;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS Node LIKEDS(Node_t) BASED(p_Node);
    DCL-DS RootNode LIKEDS(Node_t) BASED(p_RootNode);
    DCL-DS RootChildren LIKEDS(Child_t) BASED(p_RootChildren);

    DCL-S I UNS(10);
    DCL-S Nodes POINTER DIM(MAX_STATEMENTS);

    Parser_Eat(self:BEGIN);
    Nodes = Parser_Statement_List(self);
    Parser_Eat(self:END);

    p_RootNode = Compound_Init();
    p_RootChildren = RootNode.Right;
    FOR i = 1 TO %ELEM(Nodes);
        IF Nodes(i) = *NULL;
            LEAVE;
        ENDIF;
        p_Node = Nodes(i);
        RootChildren.NumChildren = i;
        RootChildren.Children(i) = Node;
    ENDFOR;

    RETURN p_RootNode;

END-PROC;



DCL-PROC Parser_Statement_List;
    DCL-PI *N POINTER DIM(MAX_STATEMENTS);
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S Results POINTER DIM(MAX_STATEMENTS);

    DCL-S I UNS(10);

    Results(1) = Parser_Statement(self);
    I = 1;

    DOW self.current_token.type = SEMI;
        Parser_Eat(self:SEMI);
        i += 1;
        Results(i) = Parser_Statement(Self);
    ENDDO;

    IF self.current_token.type = ID;
        Parser_Error(self);
    ENDIF;

    RETURN Results;

END-PROC;



DCL-PROC Parser_Statement;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    IF self.current_token.type = BEGIN;
        RETURN parser_compound_statement(self);
    ELSEIF self.current_token.type = ID;
        RETURN parser_assignment_statement(self);
    ELSE;
        RETURN parser_empty(self);
    ENDIF;

END-PROC;


DCL-PROC Parser_Assignment_Statement;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S left POINTER;
    DCL-DS token LIKEDS(Token_t);
    DCL-S right POINTER;

    left = Parser_Variable(self);
    token = self.current_token;
    Parser_Eat(self:ASSIGN);
    right = Parser_Expr(self);

    RETURN Assign_Init(left:token:right);


END-PROC;



DCL-PROC Parser_Variable;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S node POINTER;

    node = Var_Init(self.current_token);
    Parser_Eat(self:ID);

    RETURN node;

END-PROC;



DCL-PROC Parser_Empty;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S node POINTER;

    node = NoOp_Init();

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



DCL-PROC Parser_Term;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS token LIKEDS(token_t) INZ(*LIKEDS);

    DCL-S node POINTER;

    node = Parser_Factor(self);

    DOW self.current_token.type = MUL
        OR self.current_token.type = INTEGER_DIV
        OR self.current_token.type = FLOAT_DIV;

        token = self.current_token;

        IF token.type = MUL;
            Parser_Eat(self:MUL);
        ELSEIF token.type = INTEGER_DIV;
            Parser_Eat(self:INTEGER_DIV);
        ELSEIF token.type = FLOAT_DIV;
            Parser_Eat(self:FLOAT_DIV);
        ENDIF;

        node = BinOp_init(node:token:parser_factor(self));

    ENDDO;

    RETURN node;

END-PROC;



DCL-PROC Parser_Factor;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS token LIKEDS(Token_t) INZ(*LIKEDS);

    DCL-S node POINTER;

    token = self.current_token;

    IF token.type = PLUS;
        Parser_Eat(self:PLUS);
        node = UnaryOp_Init(token:Parser_Factor(self));
        RETURN node;

    ELSEIF token.type = MINUS;
        Parser_Eat(self:MINUS);
        node = UnaryOp_Init(token:Parser_Factor(self));
        RETURN node;

    ELSEIF token.type = INTEGER_CONST;
        Parser_Eat(self:INTEGER_CONST);
        RETURN Num_Init(token);

    ELSEIF token.type = REAL_CONST;
        Parser_Eat(self:REAL_CONST);
        RETURN Num_Init(token);

    ELSEIF token.type = LPAREN;
        Parser_Eat(self:LPAREN);
        node = Parser_expr(self);
        Parser_Eat(self:RPAREN);
        RETURN node;

    ELSE;
        node = Parser_Variable(self);
        RETURN node;

    ENDIF;

END-PROC;



DCL-PROC Parser_Parse EXPORT;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S Node POINTER;

    Node = Parser_Program(self);

    IF self.current_token.type <> EOF;
        Parser_Error(self);
    ENDIF;

    RETURN Node;

END-PROC;



