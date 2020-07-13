**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h
/INCLUDE headers/parser.rpgle_h
/INCLUDE headers/interpret.rpgle_h



DCL-PROC Interpreter_Init EXPORT;
    DCL-PI *N LIKEDS(Interpreter_t);
        parser LIKEDS(parser_t);
    END-PI;

    DCL-DS self LIKEDS(Interpreter_t) INZ(*LIKEDS);

    self.parser = parser;

    RETURN self;

END-PROC;



DCL-PROC Interpreter_Visit;
    DCL-PI *N LIKE(MyString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    SELECT;
    WHEN node.token.type = INTEGER;
        RETURN Interpreter_Visit_Num(p_Node);
    OTHER;
        RETURN Interpreter_Visit_BinOp(p_Node);
    ENDSL;

END-PROC;



DCL-PROC Interpreter_Visit_BinOp;
    DCL-PI *N LIKE(MyString);
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
    DCL-PI *N LIKE(MyString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    RETURN node.token.value;

END-PROC;



DCL-PROC Interpreter_Interpret EXPORT;
    DCL-PI *N LIKE(MyString);
        self LIKEDS(Interpreter_t);
    END-PI;

    DCL-S tree POINTER;

    tree = parser_parse(self.parser);

    RETURN Interpreter_visit(tree);

END-PROC;


