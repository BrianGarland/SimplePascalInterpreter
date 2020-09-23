**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/error.rpgle_h
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



DCL-PROC ProcedureSymbol_Init;
    DCL-PI *N POINTER;
        name   LIKE(ShortString) VALUE;
        type   LIKE(ShortString) VALUE OPTIONS(*NOPASS);
        params POINTER OPTIONS(*NOPASS);
    END-PI;

    DCL-DS self LIKEDS(Symbol_t) BASED(p_self);

    p_self = %ALLOC(%SIZE(Symbol_t));

    self.name = name;
    self.category = 'procedure';
    IF %PARMS >= %PARMNUM(type) AND type <> '';
        self.type = type;
    ELSE;
        self.type = 'none';
    ENDIF;
    IF %PARMS >= %PARMNUM(params);
        self.params = params;
    ENDIF;

    RETURN p_self;

END-PROC;



DCL-PROC ScopedSymbolTable_Init;
    DCL-PI *N;
        Scope_Name      LIKE(ShortString) CONST;
        Scope_Level     UNS(5) CONST;
        Enclosing_Scope UNS(5) CONST;
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
    Scope(i).Enclosing_Scope = Enclosing_Scope;

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
        name              LIKE(Symbol_t.name);
        lookup_scope_parm UNS(5) OPTIONS(*NOPASS);
    END-PI;

    DCL-S i            UNS(5) INZ(0);
    DCL-S lookup_scope UNS(5);
    DCL-S search_tree  IND INZ(FALSE);

    IF %PARMS >= %PARMNUM(lookup_scope_parm);
        lookup_scope = lookup_scope_parm;
        search_tree = TRUE;
    ELSE;
        lookup_scope = Current_Scope_ID;
    ENDIF;

    IF Scope(lookup_scope).Symbols.NumSymbols > 0;
        i = %LOOKUP(name:Scope(lookup_scope).Symbols.Symbol(*).name:
                    1:Scope(lookup_scope).Symbols.NumSymbols);
    ENDIF;

    IF i > 0;
        RETURN Scope(lookup_scope).Symbols.Symbol(i);
    ELSE;
        IF search_tree AND Scope(lookup_scope).Enclosing_Scope <> 0;
            RETURN ScopedSymbolTable_Lookup(name:Scope(lookup_scope).Enclosing_Scope);
        ELSE;
            RETURN NullSymbol;
        ENDIF;
    ENDIF;

END-PROC;



DCL-PROC SemanticAnalyzer_Init EXPORT;
    DCL-PI *N;
    END-PI;

    ScopedSymbolTable_Init('global':1:0);

    RETURN;

END-PROC;



DCL-PROC SemanticAnalyzer_Error;
    DCL-PI *N;
        error_code LIKE(ShortString) CONST;
        token      LIKEDS(Token_t);
    END-PI;

    DCL-S MsgDta VARCHAR(100);
    DCL-S MsgKey CHAR(4);

    MsgDta = 'SYMBOLS: ' + error_code + ': ''' + token.type
           + ''':''' + token.value
           + ''' line: ' + %CHAR(token.lineno)
           + ' column: ' + %CHAR(token.column);

    qmhsndpm('CPF9897':'QCPFMSG   *LIBL':MsgDta:%LEN(MsgDta):
             '*ESCAPE':'*':1:MsgKey:APIError);

END-PROC;



DCL-PROC SemanticAnalyzer_Visit EXPORT;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node LIKEDS(node_t) BASED(p_node);

    SELECT;
    WHEN node.token.type = TokenTypeID('BLOCK');
        RETURN SemanticAnalyzer_Visit_Block(p_Node);

    WHEN node.token.type = TokenTypeID('PROGRAM');
        RETURN SemanticAnalyzer_Visit_Program(p_Node);

    WHEN node.token.type = TokenTypeID('CHILDREN');
        RETURN SemanticAnalyzer_Visit_Compound(p_Node);

    WHEN node.token.type = TokenTypeID('NOOP');
        RETURN SemanticAnalyzer_Visit_NoOp(p_Node);

    WHEN node.token.type = TokenTypeID('INTEGER_CONST');
        RETURN SemanticAnalyzer_Visit_Num(p_Node);

    WHEN node.token.type = TokenTypeID('REAL_CONST');
        RETURN SemanticAnalyzer_Visit_Num(p_Node);

    WHEN (node.token.type = TokenTypeID('PLUS') OR node.token.type = TokenTypeID('MINUS'))
        AND node.left = *NULL;
        RETURN SemanticAnalyzer_Visit_UnaryOp(p_Node);

    WHEN node.token.type = TokenTypeID('PLUS')
        OR node.token.type = TokenTypeID('MINUS')
        OR node.token.type = TokenTypeID('MUL')
        OR node.token.type = TokenTypeID('INTEGER_DIV')
        OR node.token.type = TokenTypeID('FLOAT_DIV');
        RETURN SemanticAnalyzer_Visit_BinOp(p_Node);

    WHEN node.token.type = TokenTypeID('PROCEDURE');
        RETURN SemanticAnalyzer_Visit_ProcedureDecl(p_Node);

    WHEN node.token.type = TokenTypeID('VARDECL');
        RETURN SemanticAnalyzer_Visit_VarDecl(p_Node);

    WHEN node.token.type = TokenTypeID('ASSIGN');
        RETURN SemanticAnalyzer_Visit_Assign(p_Node);

    WHEN node.token.type = TokenTypeID('ID');
        RETURN SemanticAnalyzer_Visit_Var(p_Node);

    OTHER;
        SemanticAnalyzer_Error(VISIT_NOT_FOUND:node.token);

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

    DCL-S global_scope UNS(5);
    DCL-S return_value LIKE(ShortString);

    global_scope = %LOOKUP('global':scope(*).Scope_Name);
    IF global_scope = 0;
        ScopedSymbolTable_Init('global':1:0);
    ELSE;
        Current_Scope_ID = global_scope;
    ENDIF;

    return_value = SemanticAnalyzer_Visit(Node.Right);

    Current_Scope_ID = scope(Current_Scope_ID).Enclosing_Scope;

    RETURN return_value;

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



DCL-PROC SemanticAnalyzer_Visit_ProcedureDecl;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    DCL-DS node        LIKEDS(node_t) BASED(p_node);
    DCL-DS proc_symbol LIKEDS(symbol_t) BASED(p_proc_symbol);
    DCL-DS params      LIKEDS(params_t) BASED(p_params);
    DCL-DS ParamNode   LIKEDS(node_t) BASED(p_ParamNode);
    DCL-DS VarNode     LIKEDS(node_t) BASED(p_VarNode);
    DCL-DS TypeNode    LIKEDS(node_t) BASED(p_TypeNode);
    DCL-DS ParamSymbol LIKEDS(symbol_t) BASED(p_ParamSymbol);

    DCL-S i            UNS(5);
    DCL-S proc_name    LIKE(ShortString);
    DCL-S return_value LIKE(ShortString);

    proc_name = node.token.value;

    // Validate procedure name and add to current symbol table
    p_proc_symbol = %ALLOC(%SIZE(proc_symbol));
    proc_symbol = ScopedSymbolTable_Lookup(proc_name);
    IF proc_symbol.name = proc_name;
        DEALLOC p_proc_symbol;
        SemanticAnalyzer_Error(DUPLICATE_ID:Node.Token);
    ELSE;
        DEALLOC p_proc_symbol;
        p_proc_symbol = ProcedureSymbol_Init(proc_name:TokenTypeID('PROCEDURE'):Node.params);
        ScopedSymbolTable_Insert(proc_symbol);
    ENDIF;

    // Start new scope
    ScopedSymbolTable_Init(proc_name:Scope(Current_Scope_ID).Scope_Level+1:Current_Scope_ID);

    // Add parameters to symbol table
    p_params = Node.params;
    FOR i = 1 TO Params.NumNodes;
        p_ParamNode = Params.Nodes(i);
        p_VarNode = ParamNode.Left;
        p_TypeNode = ParamNode.Right;
        p_ParamSymbol = Symbol_Init(VarNode.token.value:TypeNode.token.value);
        ScopedSymbolTable_Insert(ParamSymbol);
    ENDFOR;

    return_value = SemanticAnalyzer_Visit(Node.Right);

    Current_Scope_ID = scope(current_Scope_ID).Enclosing_Scope;

    RETURN return_value;

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
    type_name = type_node.token.type;
    type_symbol = ScopedSymbolTable_Lookup(type_name:current_scope_id);

    p_left = node.left;
    var_name = var_node.token.value;

    p_var_symbol = %ALLOC(%SIZE(var_symbol));
    var_symbol = ScopedSymbolTable_Lookup(var_name);
    IF var_symbol.name = var_name;
        DEALLOC p_var_symbol;
        SemanticAnalyzer_Error(DUPLICATE_ID:var_node.token);
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

    var_symbol = ScopedSymbolTable_Lookup(var_name:Current_Scope_ID);
    IF var_symbol.name <> var_name;
        SemanticAnalyzer_Error(ID_NOT_FOUND:Node.Token);
    ENDIF;

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_Num;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    RETURN '';

END-PROC;



DCL-PROC SemanticAnalyzer_Visit_UnaryOp;
    DCL-PI *N LIKE(ShortString);
        p_node POINTER VALUE;
    END-PI;

    RETURN '';

END-PROC;

