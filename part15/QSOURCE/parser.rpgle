**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/error.rpgle_h
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
    self.token = Token_Init(TokenTypeID('CHILDREN'):'CHILDREN');
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
    self.token = Token_Init(TokenTypeID('NOOP'):' ');
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
    self.token = Token_Init(TokenTypeID('PROGRAM'):Name);
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
    self.token = Token_Init(TokenTypeID('BLOCK'):'');
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
    self.token = Token_Init(TokenTypeID('VARDECL'):'');
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



DCL-PROC Param_Init;
    DCL-PI *N POINTER;
        var_node  POINTER;
        type_node POINTER;
    END-PI;

    DCL-DS self LIKEDS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = var_node;
    self.token.type = TokenTypeID('PARAMDECL');
    self.right = type_node;

    RETURN p_Node;

END-PROC;



DCL-PROC ProcedureDecl_Init;
    DCL-PI *N POINTER;
        proc_name LIKE(shortString) VALUE;
        params POINTER;
        block_node POINTER;
    END-PI;

    DCL-DS self LIKEDS(Node_t) BASED(p_Node);

    p_Node = %ALLOC(%SIZE(Node_t));

    self.left = *NULL;
    self.token.type = TokenTypeID('PROCEDURE');
    self.token.value = proc_name;
    self.params = params;
    self.right = block_node;

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
        error_code LIKE(ShortString) CONST;
        self       LIKEDS(Parser_t);
    END-PI;

    DCL-S MsgDta VARCHAR(100);
    DCL-S MsgKey CHAR(4);

    MsgDta = 'PARSER: ' + error_code + ': ''' + self.current_token.type
           + ''' ''' + self.current_token.value
           + ''' line: ' + %CHAR(self.current_token.lineno)
           + ' column: ' + %CHAR(self.current_token.column);


    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*':1:MsgKey:APIError);

END-PROC;



DCL-PROC Parser_Eat;
    DCL-PI *N;
        self LIKEDS(Parser_t);
        token_type LIKE(ShortString) VALUE;
    END-PI;

    IF self.current_token.type = token_type;
        self.current_token = Lexer_Get_Next_Token(self.lexer);
    ELSE;
        Parser_Error(UNEXPECTED_TOKEN:self);
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

    Parser_Eat(self:TokenTypeID('PROGRAM'));
    var_p = Parser_Variable(self);
    Prog_Name = Var_Node.Token.value;
    Parser_Eat(self:TokenTypeID('SEMI'));

    Block_Node = Parser_Block(self);
    Program_Node = Program_Init(Prog_Name:Block_Node);
    Parser_Eat(self:TokenTypeID('DOT'));

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

    DCL-DS Proc_Declarations LIKEDS(node_t) DIM(MAX_STATEMENTS)
                             BASED(Proc_Declarations_p);
    DCL-DS Var_Declarations LIKEDS(node_t) DIM(MAX_STATEMENTS)
                            BASED(Var_Declarations_p);
    DCL-DS Var_Declarations2 LIKEDS(node_t) DIM(MAX_STATEMENTS)
                             BASED(Var_Declarations2_p);

    DCL-S I UNS(10) INZ;
    DCL-S J UNS(10);

    var_declarations2_p = %ALLOC(%SIZE(node_t) * MAX_STATEMENTS);

    DOW TRUE;
        SELECT;
        WHEN self.current_token.type = TokenTypeID('VAR');

            Parser_Eat(self:TokenTypeID('VAR'));
            DOW self.current_token.type = TokenTypeID('ID');
                var_declarations_p = Parser_Variable_Declaration(self);
                FOR j = 1 TO MAX_STATEMENTS;
                    IF var_Declarations(j).Token.Type = *BLANKS;
                        LEAVE;
                    ENDIF;
                    i += 1;
                    Var_Declarations2(i) = var_Declarations(j);
                ENDFOR;
                Parser_Eat(self:TokenTypeID('SEMI'));
            ENDDO;

        WHEN self.current_token.type = TokenTypeID('PROCEDURE');

            Proc_Declarations_p = Parser_Procedure_Declarations(self);
            FOR j = 1 TO MAX_STATEMENTS;
                IF Proc_Declarations(j).Token.Type = *BLANKS;
                    LEAVE;
                ENDIF;
                i += 1;
                Var_Declarations2(i) = Proc_Declarations(j);
            ENDFOR;

        OTHER;
            LEAVE;

        ENDSL;

    ENDDO;

    RETURN Var_Declarations2_p;

END-PROC;



DCL-PROC Parser_Procedure_Declarations;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS Proc_Declarations LIKEDS(node_t) DIM(MAX_STATEMENTS)
                             BASED(Proc_Declarations_p);

    DCL-S Block_Node POINTER;
    DCL-S I UNS(10) INZ;
    DCL-S Params POINTER;
    DCL-S proc_name LIKE(shortString);

    Parser_eat(self:TokenTypeID('PROCEDURE'));
    proc_name = self.current_token.value;
    Parser_eat(self:TokenTypeID('ID'));

    params = *NULL;
    IF self.current_token.type = TokenTypeID('LPAREN');
        Parser_eat(self:TokenTypeID('LPAREN'));
        params = Parser_formal_parameter_list(self);
        Parser_eat(self:TokenTypeID('RPAREN'));
    ENDIF;

    Parser_eat(self:TokenTypeID('SEMI'));
    block_node = Parser_Block(self);
    Proc_Declarations_p = ProcedureDecl_Init(proc_name:params:block_node);
    Parser_eat(self:TokenTypeID('SEMI'));

    RETURN Proc_Declarations_p;

END-PROC;



DCL-PROC Parser_Formal_Parameters;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS params LIKEDS(params_t) BASED(p_params);

    DCL-S Param_Nodes POINTER DIM(MAX_STATEMENTS);
    DCL-S I INT(10) INZ(1);
    DCL-S J INT(10) INZ(0);
    DCL-S Type_Node POINTER;

    p_params = %ALLOC(%SIZE(params));

    param_nodes(i) = Var_Init(self.current_token);

    Parser_eat(self:TokenTypeID('ID'));

    DOW self.current_token.type = TokenTypeID('COMMA');
        Parser_eat(self:TokenTypeID('COMMA'));
        i += 1;
        param_nodes(i) = Var_Init(self.current_token);
        Parser_eat(self:TokenTypeID('ID'));
    ENDDO;

    Parser_eat(self:TokenTypeID('COLON'));

    type_node = Parser_Type_Spec(self);

    FOR j = 1 TO i;
        params.Nodes(j) = Param_Init(param_nodes(j):Type_Node);
    ENDFOR;
    params.NumNodes = i;

    RETURN p_params;

END-PROC;



DCL-PROC Parser_Formal_Parameter_List;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-DS params1 LIKEDS(params_t) BASED(p_params1);
    DCL-DS params2 LIKEDS(params_t) BASED(p_params2);

    DCL-S I UNS(5);

    p_params2 = %ALLOC(%SIZE(params2));
    params2.NumNodes = 0;

    IF self.current_token.type <> TokenTypeID('ID');
        RETURN p_params2;
    ENDIF;

    p_params1 = Parser_Formal_Parameters(self);
    FOR i = 1 TO params1.NumNodes;
        params2.NumNodes += 1;
        params2.Nodes(params2.NumNodes) = params1.Nodes(i);
    ENDFOR;

    DOW self.current_token.type = TokenTypeID('SEMI');
        Parser_eat(self:TokenTypeID('SEMI'));
        p_params1 = Parser_Formal_Parameters(self);
        FOR i = 1 TO params1.NumNodes;
            params2.NumNodes += 1;
            params2.Nodes(params2.NumNodes) = params1.Nodes(i);
        ENDFOR;
    ENDDO;

    RETURN p_params2;

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
    Parser_Eat(self:TokenTypeID('ID'));

    DOW self.current_token.type = TokenTypeID('COMMA');
        Parser_Eat(self:TokenTypeID('COMMA'));
        i += 1;
        var_nodes(i) = Var_Init(self.current_Token);
        Parser_Eat(self:TokenTypeID('ID'));
    ENDDO;

    Parser_Eat(self:TokenTypeID('COLON'));

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

    IF self.current_token.type = TokenTypeID('INTEGER');
        Parser_Eat(self:TokenTypeID('INTEGER'));
    ELSE;
        Parser_Eat(self:TokenTypeID('REAL'));
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

    Parser_Eat(self:TokenTypeID('BEGIN'));
    Nodes = Parser_Statement_List(self);
    Parser_Eat(self:TokenTypeID('END'));

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

    DOW self.current_token.type = TokenTypeID('SEMI');
        Parser_Eat(self:TokenTypeID('SEMI'));
        i += 1;
        Results(i) = Parser_Statement(Self);
    ENDDO;

    RETURN Results;

END-PROC;



DCL-PROC Parser_Statement;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    IF self.current_token.type = TokenTypeID('BEGIN');
        RETURN parser_compound_statement(self);
    ELSEIF self.current_token.type = TokenTypeID('ID');
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
    Parser_Eat(self:TokenTypeID('ASSIGN'));
    right = Parser_Expr(self);

    RETURN Assign_Init(left:token:right);


END-PROC;



DCL-PROC Parser_Variable;
    DCL-PI *N POINTER;
        self LIKEDS(Parser_t);
    END-PI;

    DCL-S node POINTER;

    node = Var_Init(self.current_token);
    Parser_Eat(self:TokenTypeID('ID'));

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

    DOW self.current_token.type = TokenTypeID('PLUS')
        OR self.current_token.type = TokenTypeID('MINUS');

        token = self.current_token;

        IF token.type = TokenTypeID('PLUS');
            Parser_Eat(self:TokenTypeID('PLUS'));
        ELSEIF token.type = TokenTypeID('MINUS');
            Parser_Eat(self:TokenTypeID('MINUS'));
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

    DOW self.current_token.type = TokenTypeID('MUL')
        OR self.current_token.type = TokenTypeID('INTEGER_DIV')
        OR self.current_token.type = TokenTypeID('FLOAT_DIV');

        token = self.current_token;

        IF token.type = TokenTypeID('MUL');
            Parser_Eat(self:TokenTypeID('MUL'));
        ELSEIF token.type = TokenTypeID('INTEGER_DIV');
            Parser_Eat(self:TokenTypeID('INTEGER_DIV'));
        ELSEIF token.type = TokenTypeID('FLOAT_DIV');
            Parser_Eat(self:TokenTypeID('FLOAT_DIV'));
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

    IF token.type = TokenTypeID('PLUS');
        Parser_Eat(self:TokenTypeID('PLUS'));
        node = UnaryOp_Init(token:Parser_Factor(self));
        RETURN node;

    ELSEIF token.type = TokenTypeID('MINUS');
        Parser_Eat(self:TokenTypeID('MINUS'));
        node = UnaryOp_Init(token:Parser_Factor(self));
        RETURN node;

    ELSEIF token.type = TokenTypeID('INTEGER_CONST');
        Parser_Eat(self:TokenTypeID('INTEGER_CONST'));
        RETURN Num_Init(token);

    ELSEIF token.type = TokenTypeID('REAL_CONST');
        Parser_Eat(self:TokenTypeID('REAL_CONST'));
        RETURN Num_Init(token);

    ELSEIF token.type = TokenTypeID('LPAREN');
        Parser_Eat(self:TokenTypeID('LPAREN'));
        node = Parser_expr(self);
        Parser_Eat(self:TokenTypeID('RPAREN'));
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

    IF self.current_token.type <> TokenTypeID('EOF');
        Parser_Error(UNEXPECTED_TOKEN:self);
    ENDIF;

    RETURN Node;

END-PROC;



