**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/lexer.rpgle_h
/INCLUDE headers/parser.rpgle_h
/INCLUDE headers/symbols.rpgle_h



DCL-DS NullSymbol  LIKEDS(Symbol_t);


DCL-DS Scope     LIKEDS(ScopedSymbolTable_t) INZ(*LIKEDS) DIM(50) EXPORT;
DCL-S  NumScopes UNS(5) INZ(0) EXPORT;


DCL-S Current_Scope_ID UNS(5) INZ(0);



DCL-PROC Symbol_Init;
    DCL-PI *N POINTER;
        name LIKE(ShortString) VALUE;
        type LIKE(ShortString) VALUE OPTIONS(*NOPASS);
    END-PI;

    DCL-DS self LIKEDS(Symbol_t) BASED(p_self);

    p_self = %ALLOC(%SIZE(Symbol_t));

    self.name = name;
    self.category = 'none';
    IF %PARMS >= %PARMNUM(type) AND type <> '';
        self.type = type;
    ELSE;
        self.type = 'none';
    ENDIF;

    RETURN p_self;

END-PROC;



DCL-PROC VarSymbol_Init;
    DCL-PI *N POINTER;
        name LIKE(ShortString) VALUE;
        type LIKE(ShortString) VALUE OPTIONS(*NOPASS);
    END-PI;

    DCL-DS self LIKEDS(Symbol_t) BASED(p_self);

    p_self = %ALLOC(%SIZE(Symbol_t));

    self.name = name;
    self.category = 'variable';
    IF %PARMS >= %PARMNUM(type) AND type <> '';
        self.type = type;
    ELSE;
        self.type = 'none';
    ENDIF;

    RETURN p_self;

END-PROC;



DCL-PROC BuiltinTypeSymbol_Init;
    DCL-PI *N POINTER;
        name LIKE(ShortString) VALUE;
        type LIKE(ShortString) VALUE OPTIONS(*NOPASS);
    END-PI;

    DCL-DS self LIKEDS(Symbol_t) BASED(p_self);

    p_self = %ALLOC(%SIZE(Symbol_t));

    self.name = name;
    self.category = 'built-in';
    IF %PARMS >= %PARMNUM(type) AND type <> '';
        self.type = type;
    ELSE;
        self.type = 'none';
    ENDIF;

    RETURN p_self;

END-PROC;



DCL-PROC ScopedSymbolTable_Init;
    DCL-PI *N;
        Scope_Name  LIKE(ShortString) CONST;
        Scope_Level UNS(5) CONST;
    END-PI;

    DCL-S i UNS(5) INZ(0);

    IF NumScopes > 0;
        i = %LOOKUP(Scope_Name:Scope(*).Scope_Name:1:NumScopes);
    ENDIF;

    IF i = 0;
        NumScopes += 1;
        i = NumScopes;
    ENDIF;

    RESET Scope(i).Symbols;
    Scope(i).Scope_Name = Scope_Name;
    Scope(i).Scope_Level = Scope_Level;

    Current_Scope_ID = i;

    SymbolTable_Init_Builtins();

    RESET NullSymbol;
    NullSymbol.name     = 'null';
    NullSymbol.category = 'null';
    NullSymbol.type     = 'null';

    RETURN;

END-PROC;



DCL-PROC SymbolTable_Init_Builtins;
    DCL-PI *N;
    END-PI;

    DCL-DS symbol LIKEDS(symbol_t) BASED(p_symbol);

    p_symbol = BuiltinTypeSymbol_Init('INTEGER');
    ScopedSymbolTable_Insert(symbol);

    p_symbol = BuiltinTypeSymbol_Init('REAL');
    ScopedSymbolTable_Insert(symbol);

    RETURN;

END-PROC;



DCL-PROC ScopedSymbolTable_Insert;
    DCL-PI *N;
        self LIKEDS(Symbol_t) VALUE;
    END-PI;

    DCL-S i UNS(5) INZ(0);

    IF Scope(Current_Scope_ID).Symbols.NumSymbols > 0;
        i = %LOOKUP(self.name:Scope(Current_Scope_ID).Symbols.Symbol(*).name:
                    1:Scope(Current_Scope_ID).Symbols.NumSymbols);
    ENDIF;

    IF i =0;
        Scope(Current_Scope_ID).Symbols.NumSymbols += 1;
        i = Scope(Current_Scope_ID).Symbols.NumSymbols;
    ENDIF;

    Scope(Current_Scope_ID).Symbols.Symbol(i) = self;

    RETURN;

END-PROC;



DCL-PROC ScopedSymbolTable_Lookup;
    DCL-PI *N LIKEDS(Symbol_t);
        name LIKE(Symbol_t.name);
    END-PI;

    DCL-S i UNS(5) INZ(0);

    IF Scope(Current_Scope_ID).Symbols.NumSymbols > 0;
        i = %LOOKUP(name:Scope(Current_Scope_ID).Symbols.Symbol(*).name:
                    1:Scope(Current_Scope_ID).Symbols.NumSymbols);
    ENDIF;

    IF i > 0;
        RETURN Scope(Current_Scope_ID).Symbols.Symbol(i);
    ELSE;
        RETURN NullSymbol;
    ENDIF;

END-PROC;



DCL-PROC SemanticAnalyzer_Init EXPORT;
    DCL-PI *N;
    END-PI;

    ScopedSymbolTable_Init('global':1);

    RETURN;

END-PROC;



DCL-PROC SemanticAnalyzer_Error;
    DCL-PI *N;
        MsgDta VARCHAR(100) VALUE;
    END-PI;

    DCL-S MsgKey CHAR(4);

    MsgDta = 'SYMBOLS: ' + MsgDta;

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*':1:MsgKey:ErrorCode);

END-PROC;



DCL-PROC SemanticAnalyzer_Visit EXPORT;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    SELECT;
    WHEN node.token.type = BLOCK;
        RETURN SemanticAnalyzer_Visit_Block(p_Node);

    WHEN node.token.type = PROGRAM;
        RETURN SemanticAnalyzer_Visit_Program(p_Node);

    WHEN node.token.type = CHILDREN;
        RETURN SemanticAnalyzer_Visit_Compound(p_Node);

    WHEN node.token.type = NOOP;
        RETURN SemanticAnalyzer_Visit_NoOp(p_Node);

    WHEN node.token.type = PLUS
        OR node.token.type = MINUS
        OR node.token.type = MUL
        OR node.token.type = INTEGER_DIV
        OR node.token.type = FLOAT_DIV;
        RETURN SemanticAnalyzer_Visit_BinOp(p_Node);

    WHEN node.token.type = VARDECL;
        RETURN SemanticAnalyzer_Visit_VarDecl(p_Node);

    WHEN node.token.type = ASSIGN;
        RETURN SemanticAnalyzer_Visit_Assign(p_Node);

    WHEN node.token.type = ID;
        RETURN SemanticAnalyzer_Visit_Var(p_Node);

    OTHER;
        SemanticAnalyzer_Error('No visit defined for ' + node.token.type);

    ENDSL;

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_Block;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);
    DCL-DS Var_Declarations LIKEDS(node_t) DIM(MAX_STATEMENTS)
                            BASED(Var_Declarations_p);
    DCL-S I UNS(5);

    Var_Declarations_p = Node.Left;

    FOR i = 1 TO MAX_STATEMENTS;
        IF var_Declarations(i).Token.Type = *BLANKS;
            LEAVE;
        ENDIF;
        SemanticAnalyzer_Visit(%ADDR(Var_Declarations(i)));
    ENDFOR;

    RETURN SemanticAnalyzer_Visit(Node.Right);

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_Program;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    RETURN SemanticAnalyzer_Visit(Node.Right);

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_Compound;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS Child LIKEDS(Child_t) BASED(p_Child);
    DCL-DS Node LIKEDS(Node_t) BASED(p_Node);

    DCL-S i UNS(10);

    p_Child = Node.Right;

    FOR i = 1 TO Child.NumChildren;
        SemanticAnalyzer_Visit(%ADDR(Child.Children(i)));
    ENDFOR;

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_NoOp;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_BinOp;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    SemanticAnalyzer_Visit(node.left);
    SemanticAnalyzer_Visit(node.right);

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_VarDecl;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node        LIKEDS(node_t) BASED(p_node);
    DCL-DS type_node   LIKEDS(node_t) BASED(p_right);
    DCL-DS var_node    LIKEDS(node_t) BASED(p_left);
    DCL-DS type_symbol LIKEDS(symbol_t);
    DCL-DS var_symbol  LIKEDS(symbol_t) BASED(p_var_symbol);

    DCL-S type_name LIKE(ShortString);
    DCL-S var_name  LIKE(ShortString);

    p_right = node.right;
    type_name = type_node.token.value;
    type_symbol = ScopedSymbolTable_Lookup(type_name);

    p_left = node.left;
    var_name = var_node.token.value;

    p_var_symbol = %ALLOC(%SIZE(var_symbol));
    var_symbol = ScopedSymbolTable_Lookup(var_name);
    IF var_symbol.name = var_name;
        DEALLOC p_var_symbol;
        SemanticAnalyzer_Error('Duplicate identifier ' + var_name + ' found.');
    ELSE;
        DEALLOC p_var_symbol;
        p_var_symbol = VarSymbol_Init(var_name:type_name);
        ScopedSymbolTable_Insert(var_symbol);
    ENDIF;

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_Assign;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS Node LIKEDS(Node_t) BASED(p_Node);

    SemanticAnalyzer_Visit(Node.Right);

    SemanticAnalyzer_Visit(Node.Left);

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_Var;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS Node       LIKEDS(Node_t) BASED(p_Node);
    DCL-DS var_symbol LIKEDS(Symbol_t);

    DCL-S Var_Name LIKE(ShortString);

    Var_Name = Node.Token.Value;

    var_symbol = ScopedSymbolTable_Lookup(var_name);
    IF var_symbol.name <> var_name;
        SemanticAnalyzer_Error('Identifier not found: ' + Var_Name);
    ENDIF;

    RETURN '';

END-PROC;


