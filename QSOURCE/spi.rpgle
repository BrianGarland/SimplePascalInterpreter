**FREE

    //
    // The UI portion of a Simple Pascal Interpreter for IBM i
    //
    // Copyright 2020, Brian J Garland
    //

    DCL-F SPIFM WORKSTN INFDS(DSPFDS);

    DCL-PI SPI;
        ShowScope CHAR(4);
        ShowStack CHAR(4);
    END-PI;

    /INCLUDE headers/stdio.rpgle_h
    /INCLUDE headers/util.rpgle_h
    /INCLUDE headers/memory.rpgle_h
    /INCLUDE headers/lexer.rpgle_h
    /INCLUDE headers/parser.rpgle_h
    /INCLUDE headers/symbols.rpgle_h
    /INCLUDE headers/interpret.rpgle_h

    DCL-DS Scope LIKEDS(ScopedSymbolTable_t) DIM(50) IMPORT;
    DCL-S NumScopes UNS(5) IMPORT;

    DCL-S Log LIKE(ShortString) DIM(10000) IMPORT;
    DCL-S Last_Log UNS(5) IMPORT;

    DCL-C #EXIT      x'33'; //F3
    DCL-C #RUN       x'38'; //F8
    DCL-C #LIST      x'39'; //F9
    DCL-C #LOAD      x'3A'; //F10
    DCL-C #SAVE      x'3B'; //F11
    DCL-C #CANCEL    x'3C'; //F12
    DCL-C #TOP       x'B5'; //F17
    DCL-C #BOTTOM    x'B6'; //F18
    DCL-C #PAGEUP    X'F4'; //Page Up
    DCL-C #PAGEDOWN  X'F5'; //Page Down

    DCL-C Offset     2;

    DCL-DS DSPFDS;
        FKey CHAR(1) POS(369);
    END-DS;

    DCL-DS LineDS;
        Line01;
        Line02;
        Line03;
        Line04;
        Line05;
        Line06;
        Line07;
        Line08;
        Line09;
        Line10;
        Line11;
        Line12;
        Line13;
        Line14;
        Line15;
        Line16;
        Line17;
        Line18;
        Line19;
        Line20;
        Line21;
        Line22;
        Line23;
        Line24;
        Line LIKE(Line01) DIM(24) POS(1);
    END-DS;

    DCL-DS Listing DIM(1000) QUALIFIED;
        Line#     ZONED(5:0) INZ(0);
        Statement LIKE(Line01) INZ('');
    END-DS;

    DCL-S AllDone      IND INZ(*OFF);
    DCL-S CurrentLine  UNS(5);
    DCL-S History      LIKE(Line01) DIM(10000);
    DCL-S HistoryLines UNS(5) INZ(0);
    DCL-S I            UNS(5);
    DCL-S J            UNS(5);
    DCL-S ListingLines UNS(5) INZ(0);



    Title1 = Center1('SPI - Simple Pascal Interpreter');
    CurrentLine = 0;

    DOU AllDone;

        j = 0;
        CLEAR Line;
        IF CurrentLine > 0;
            FOR i = CurrentLine TO HistoryLines;
                IF j >= %ELEM(Line);
                    sln = 0;
                    LEAVE;
                ENDIF;
                j += 1;
                Line(j) = History(i);
                sln = j + Offset;
            ENDFOR;
        ELSE;
            sln = Offset;
        ENDIF;

        IF sln = 0;
            EXFMT S1;
        ELSE;
            WRITE S1;
            EXFMT S2;
        ENDIF;

        SELECT;
        WHEN FKey = #EXIT;
            AllDone = *ON;

        WHEN FKey = #RUN;
            RunFile();
            FindBottom();

        WHEN FKey = #LIST;
            ListFile();
            FindBottom();

        WHEN FKey = #LOAD;
            LoadFile();
            FindBottom();

        WHEN FKey = #SAVE;
            SaveFile();
            FindBottom();

        WHEN FKey = #TOP;
            CurrentLine = 1;

        WHEN FKey = #BOTTOM;
            FindBottom();

        WHEN FKey = #PAGEUP;
            IF CurrentLine > %ELEM(Line);
                CurrentLine -= %ELEM(Line);
            ELSE;
                CurrentLine = 1;
            ENDIF;

        WHEN FKey = #PAGEDOWN;
            IF (CurrentLine + %ELEM(Line)) <= HistoryLines;
                CurrentLine += %ELEM(Line);
            ENDIF;

        OTHER;

            // check input for valid values
            // a) starts with a number => add to listing
            // b) probably switch from f-keys to commands for RUN, LOAD, SAVE, LIST

            UpdateListing(Input);

            HistoryLines += 1;
            History(HistoryLines) = '> ' + Input;

            Input = '';
            IF CurrentLine = 0 OR HistoryLines > %ELEM(Line)-2;
                CurrentLine += 1;
            ENDIF;

        ENDSL;

    ENDDO;

    *INLR = *ON;
    RETURN;



    //------------------------------------------------------------------------
    DCL-PROC FindBottom;
    //------------------------------------------------------------------------
    DCL-PI *n;
    END-PI;

        IF HistoryLines > %ELEM(Line) - 2;
            CurrentLine = HistoryLines - (%ELEM(Line) - 2) + 1;
        ELSE;
            CurrentLine = 1;
        ENDIF;

        RETURN;

    END-PROC;



    //------------------------------------------------------------------------
    DCL-PROC Center1;
    //------------------------------------------------------------------------
    DCL-PI *n LIKE(Title1);
        StringIn LIKE(Title1) CONST;
    END-PI;

        DCL-S Pos       UNS(5);
        DCL-S StringOut LIKE(Title1) INZ;

        Pos = (%SIZE(StringOut)/2+1) - (%LEN(%TRIM(StringIn))/2);
        %SUBST(StringOut:Pos) = %TRIM(StringIn);

        RETURN StringOut;

    END-PROC;



    //------------------------------------------------------------------------
    DCL-PROC Center3;
    //------------------------------------------------------------------------
    DCL-PI *n LIKE(Title3);
        StringIn LIKE(Title3) CONST;
    END-PI;

        DCL-S Pos       UNS(5);
        DCL-S StringOut LIKE(Title1) INZ;

        Pos = (%SIZE(StringOut)/2+1) - (%LEN(%TRIM(StringIn))/2);
        %SUBST(StringOut:Pos) = %TRIM(StringIn);

        RETURN StringOut;

    END-PROC;



    //------------------------------------------------------------------------
    DCL-PROC UpdateListing;
    //------------------------------------------------------------------------
    DCL-PI *n;
        InputLine LIKE(Input);
    END-PI;

        DCL-S Index     ZONED(5:0) INZ(0);
        DCL-S Line#     ZONED(5:0) INZ(0);
        DCL-S Separator UNS(5) INZ(0);
        DCL-S Statement LIKE(Line01) INZ('');

        IF InputLine <> '';

            Separator = %SCAN(' ':InputLine);
            IF Separator > 0;

                MONITOR;
                    Line# = %DEC(%SUBST(InputLine:1:Separator-1):5:0);
                    IF Separator < %LEN(InputLine);
                        Statement = %SUBST(InputLine:Separator+1);
                    ENDIF;
                ON-ERROR;
                ENDMON;

                IF Line# <> 0;
                    Index = %LOOKUP(Line#:Listing(*).Line#);
                    SELECT;
                    WHEN Index > 0 AND Statement = *BLANKS;
                        // delete line
                    WHEN Index > 0 AND Statement <> *BLANKS;
                        // update existing line
                        Listing(Index).Statement = Statement;
                    WHEN Index = 0 AND Statement <>*BLANKS;
                        // add a new line
                        ListingLines += 1;
                        Listing(ListingLines).Line# = Line#;
                        Listing(ListingLines).Statement = Statement;
                    ENDSL;
                ENDIF;

            ENDIF;

        ENDIF;

        RETURN;

    END-PROC;



    //------------------------------------------------------------------------
    DCL-PROC RunFile;
    //------------------------------------------------------------------------
    DCL-PI *N;
    END-PI;

        DCL-DS interpreter LIKEDS(Interpreter_t) INZ(*LIKEDS);
        DCL-DS lexer       LIKEDS(Lexer_t) INZ(*LIKEDS);
        DCL-DS parser      LIKEDS(Parser_t) INZ(*LIKEDS);
        DCL-DS parser2     LIKEDS(Parser_t) INZ(*LIKEDS);

        DCL-DS Params      LIKEDS(Params_t) BASED(p_Params);
        DCL-DS ParamNode   LIKEDS(node_t) BASED(p_ParamNode);
        DCL-DS VarNode     LIKEDS(node_t) BASED(p_VarNode);
        DCL-DS TypeNode    LIKEDS(node_t) BASED(p_TypeNode);

        DCL-S i      UNS(5);
        DCL-S l      UNS(5);
        DCL-S p_Tree POINTER;
        DCL-S s      UNS(5);
        DCL-S Text   LIKE(LongString) INZ('');
        DCL-S Result LIKE(ShortString);

        HistoryLines += 1;
        History(HistoryLines) = '> RUN';

        FOR i = 1 TO ListingLines;
            Text += %TRIMR(Listing(i).Statement) + LF;
        ENDFOR;

        MONITOR;
            lexer = Lexer_Init(text);
            parser = Parser_Init(lexer);
            parser2 = parser;

            p_tree = Parser_Parse(parser);
            SemanticAnalyzer_Init();
            SemanticAnalyzer_Visit(p_tree);

            Interpreter = Interpreter_Init(parser2);
            Result = Interpreter_Interpret(Interpreter);

            IF ShowScope = '*YES';

                HistoryLines += 1;
                History(HistoryLines) = '';

                HistoryLines += 1;
                History(HistoryLines) = '  SCOPE (Scoped Symbol Table)';
                HistoryLines += 1;
                History(HistoryLines) = '  ===========================';
                FOR s = 1 TO NumScopes;
                    HistoryLines += 1;
                    History(HistoryLines) = '';
                    HistoryLines += 1;
                    History(HistoryLines) = '  Scope Name      : '
                                          + Scope(s).Scope_Name;
                    HistoryLines += 1;
                    History(HistoryLines) = '  Scope Level     : '
                                          + %CHAR(Scope(s).Scope_Level);
                    IF Scope(s).Enclosing_Scope = 0;
                        HistoryLines += 1;
                        History(HistoryLines) = '  Enclosing scope : none';
                    ELSE;
                        HistoryLines += 1;
                        History(HistoryLines) = '  Enclosing scope : '
                                + %CHAR(Scope(Scope(s).Enclosing_Scope).Scope_Name);
                    ENDIF;
                    HistoryLines += 1;
                    History(HistoryLines) = '  Scope (Scoped Symbol Table) Contents';
                    HistoryLines += 1;
                    History(HistoryLines) = '  ------------------------------------';
                    FOR i = 1 TO Scope(s).Symbols.NumSymbols;
                        result = '{"name":"'
                               + Scope(s).Symbols.Symbol(i).name + '"'
                               + ',"category":"'
                               + Scope(s).Symbols.Symbol(i).category + '"'
                               + ',"type":"'
                               + Scope(s).Symbols.Symbol(i).type;
                        IF Scope(s).Symbols.Symbol(i).type = TokenTypeID('PROCEDURE')
                            AND Scope(s).Symbols.Symbol(i).params <> *NULL;
                            result += ',"parameters":[';
                            p_Params = Scope(s).Symbols.Symbol(i).params;
                            FOR j = 1 TO Params.NumNodes;
                                p_ParamNode = Params.Nodes(j);
                                p_VarNode = ParamNode.Left;
                                p_TypeNode = ParamNode.Right;
                                result += '{"' + VarNode.token.value + '","'
                                        + TypeNode.token.value + '"}';
                            ENDFOR;
                            result += ']';
                        ENDIF;
                        result += '"}';
                        HistoryLines += 1;
                        History(HistoryLines) = '  ' + result;
                    ENDFOR;
                ENDFOR;

            ENDIF;

            IF ShowStack = '*YES';

                HistoryLines += 1;
                History(HistoryLines) = '';

                FOR l = 1 TO Last_Log;
                    HistoryLines += 1;
                    History(HistoryLines) = Log(l);
                ENDFOR;

            ENDIF;

        ON-ERROR;

            HistoryLines += 1;
            History(HistoryLines) = '';

            HistoryLines += 1;
            History(HistoryLines) = '  An error occured:';

            QMHRCVPM(RCVM0100DS:%SIZE(RCVM0100DS):'RCVM0100':'*':0:'*ESCAPE':
                     '':0:'*SAME':APIError);
            HistoryLines += 1;
            History(HistoryLines) = '  ' + %SUBST(RCVM0100DS.MsgData:1:
                                                  RCVM0100DS.LenDataRet);

        ENDMON;

        RETURN;

    END-PROC;


    //------------------------------------------------------------------------
    DCL-PROC ListFile;
    //------------------------------------------------------------------------
    DCL-PI *N;
    END-PI;

        HistoryLines += 1;
        History(HistoryLines) = '> LIST';

        FOR i = 1 TO ListingLines;

            HistoryLines += 1;
            History(HistoryLines) = '  '
                                  + %EDITC(Listing(i).Line#:'X')
                                  + ' ' + Listing(i).Statement;

        ENDFOR;

        RETURN;

    END-PROC;



    //------------------------------------------------------------------------
    DCL-PROC LoadFile;
    //------------------------------------------------------------------------
    DCL-PI *N;
    END-PI;

        DCL-S Buffer    CHAR(1000);
        DCL-S BufferLen UNS(5);
        DCL-S LoadDone  IND INZ(FALSE);
        DCL-S Options   VARCHAR(100);
        DCL-S Stream    LIKE(pFile);
        DCL-S Success   POINTER;

        Title3 = Center3('Load a file');

        DOU LoadDone;

            EXFMT S3;
            IF FKey = #CANCEL;
                LoadDone = TRUE;
                HistoryLines += 1;
                History(HistoryLines) = '  LOAD canceled.';
                LEAVE;
            ENDIF;

            Options = 'r, crln=Y';
            Stream = fopen(%TRIMR(FileName):Options);
            IF Stream = *NULL;
                s3Error = 'Error opening file';
                LoadDone = FALSE;
                ITER;
            ENDIF;

            HistoryLines += 1;
            History(HistoryLines) = '> LOAD "' + %TRIMR(FileName) + '"';

            RESET Listing;

            ListingLines = 0;

            CLEAR Buffer;
            Success = fgets(%ADDR(Buffer):%SIZE(Buffer):Stream);
            DOU Success = *NULL;

                BufferLen = %LEN(%TRIMR(Buffer));
                Buffer = %SCANRPL(NULL:' ':Buffer:1:BufferLen);
                Buffer = %SCANRPL(CR:' ':Buffer:1:BufferLen);
                Buffer = %SCANRPL(LF:' ':Buffer:1:BufferLen);

                ListingLines += 1;
                Listing(ListingLines).Line# = ListingLines * 10;
                Listing(ListingLines).Statement = Buffer;

                CLEAR Buffer;
                Success = fGets(%ADDR(Buffer):%SIZE(Buffer):Stream);

            ENDDO;

            fClose(Stream);

            HistoryLines += 1;
            History(HistoryLines) = '  ' + %CHAR(ListingLines)
                                  + ' statements loaded.';

            LoadDone = TRUE;

        ENDDO;

        RETURN;

    END-PROC;



    //------------------------------------------------------------------------
    DCL-PROC SaveFile;
    //------------------------------------------------------------------------
    DCL-PI *N;
    END-PI;

        DCL-S Buffer   VARCHAR(1000);
        DCL-S Options  VARCHAR(100);
        DCL-S SaveDone IND INZ(FALSE);
        DCL-S Stream   LIKE(pFile);

        Title3 = Center3('Save a file');

        DOU SaveDone;

            EXFMT S3;
            IF FKey = #CANCEL;
                SaveDone = TRUE;
                HistoryLines += 1;
                History(HistoryLines) = '  SAVE canceled.';
                LEAVE;
            ENDIF;

            Options = 'w, crln=Y, o_ccsid=1208';
            Stream = fOpen(%TRIMR(FileName):Options);
            IF Stream = *NULL;
                s3Error = 'Error opening file';
                SaveDone = FALSE;
                ITER;
            ENDIF;

            fClose(Stream);
            Options = 'w, crln=Y, o_ccsid=0';
            Stream = fOpen(%TRIMR(FileName):Options);
            IF Stream = *NULL;
                s3Error = 'Error opening file';
                SaveDone = FALSE;
                ITER;
            ENDIF;

            HistoryLines += 1;
            History(HistoryLines) = '> SAVE "' + %TRIMR(FileName) + '"';

            FOR i = 1 TO ListingLines;
                Buffer = %TRIMR(Listing(i).Statement) + LF;
                fPuts(Buffer:Stream);
            ENDFOR;

            fClose(Stream);

            HistoryLines += 1;
            History(HistoryLines) = '  ' + %CHAR(ListingLines)
                                  + ' statements saved.';

            SaveDone = TRUE;

        ENDDO;

        RETURN;

    END-PROC;


