**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h
/INCLUDE headers/parser.rpgle_h
/INCLUDE headers/interpret.rpgle_h


DCL-DS GLOBAL_SCOPE QUALIFIED DIM(MAX_STATEMENTS) EXPORT;
    id     LIKE(ShortString) INZ('');
    value  LIKE(ShortString) INZ('');
END-DS;


DCL-PROC Interpreter_Init EXPORT;
    DCL-PI *N LIKEDS(Interpreter_t);
        parser LIKEDS(parser_t);
    END-PI;

    DCL-DS self LIKEDS(Interpreter_t) INZ(*LIKEDS);

    self.parser = parser;

    RETURN self;

END-PROC;



DCL-PROC Interpreter_Error;
    DCL-PI *N;
        MsgDta VARCHAR(100) VALUE;
    END-PI;

    DCL-S MsgKey CHAR(4);

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*PGMBDY':1:MsgKey:ErrorCode);

END-PROC;



DCL-PROC Interpreter_Visit;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    SELECT;
    WHEN node.token.type = NOOP;
        RETURN Interpreter_Visit_NoOp(p_Node);

    WHEN node.token.type = INTEGER;
        RETURN Interpreter_Visit_Num(p_Node);

    WHEN (node.token.type = PLUS OR node.token.type = MINUS)
        AND node.left = *NULL;
        RETURN Interpreter_Visit_UnaryOp(p_Node);

    WHEN node.token.type = CHILDREN;
        RETURN Interpreter_Visit_Compound(p_Node);

    WHEN node.token.type = ASSIGN;
        RETURN Interpreter_Visit_Assign(p_Node);

    WHEN node.token.type = ID;
        RETURN Interpreter_Visit_Var(p_Node);

    OTHER;
        RETURN Interpreter_Visit_BinOp(p_Node);

    ENDSL;

END-PROC;



DCL-PROC Interpreter_Visit_BinOp;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    DCL-S Left INT(10);
    DCL-S Right INT(10);
    DCL-S Result INT(10);

    Left = %INT(Interpreter_Visit(node.left));
    Right = %INT(Interpreter_Visit(node.right));

    SELECT;
    WHEN node.token.type = PLUS;
        EVAL(H) Result = Left + Right;
    WHEN node.token.type = MINUS;
        EVAL(H) Result = Left - Right;
    WHEN node.token.type = MUL;
        EVAL(H) Result = Left * Right;
    WHEN node.token.type = DIV;
        EVAL(H) Result = Left / Right;
    ENDSL;

    RETURN %CHAR(Result);

END-PROC;



DCL-PROC Interpreter_Visit_Num;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    RETURN node.token.value;

END-PROC;



DCL-PROC Interpreter_Visit_UnaryOp;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    DCL-S Right INT(10);
    DCL-S Result INT(10);

    Right = %INT(Interpreter_Visit(node.right));

    SELECT;
    WHEN node.token.type = PLUS;
        Result = Right;
    WHEN node.token.type = MINUS;
        Result = -Right;
    ENDSL;

    RETURN %CHAR(Result);

END-PROC;



DCL-PROC Interpreter_Visit_Compound;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS Child LIKEDS(Child_t) BASED(p_Child);
    DCL-DS Node LIKEDS(Node_t) BASED(p_Node);

    DCL-S i UNS(10);

    p_Child = Node.Right;

    FOR i = 1 TO Child.NumChildren;
        Interpreter_Visit(%ADDR(Child.Children(i)));
    ENDFOR;

    RETURN '';

END-PROC;



DCL-PROC Interpreter_Visit_Assign;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS Node LIKEDS(Node_t) BASED(p_Node);
    DCL-DS Node2 LIKEDS(Node_t) BASED(p_Node2);

    DCL-S i UNS(10);
    DCL-S Var_Name LIKE(ShortString);

    p_Node2 = Node.Left;
    Var_Name = Node2.Token.Value;

    i = %LOOKUP(Var_Name:GLOBAL_SCOPE(*).id);
    IF i = 0;
        i = %LOOKUP(' ':GLOBAL_SCOPE(*).id);
    ENDIF;
    GLOBAL_SCOPE(i).id = Var_name;
    GLOBAL_SCOPE(i).value = Interpreter_Visit(node.right);

    RETURN '';

END-PROC;



DCL-PROC Interpreter_Visit_Var;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS Node LIKEDS(Node_t) BASED(p_Node);

    DCL-S i UNS(10);
    DCL-S Var_Name LIKE(ShortString);

    Var_Name = Node.Token.Value;

    i = %LOOKUP(Var_Name:GLOBAL_SCOPE(*).id);
    IF i = 0;
        Interpreter_Error('Name error: ' + Var_Name);
    ELSE;
        RETURN GLOBAL_SCOPE(i).value;
    ENDIF;

END-PROC;



DCL-PROC Interpreter_Visit_NoOp;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    RETURN '';

END-PROC;



DCL-PROC Interpreter_Interpret EXPORT;
    DCL-PI *N LIKE(ShortString);
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-S tree POINTER;

    tree = parser_parse(self.parser);

    RETURN Interpreter_visit(tree);

END-PROC;


