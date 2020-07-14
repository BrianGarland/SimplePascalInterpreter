**FREE

/include headers/util.rpgle_h
/include headers/lexer.rpgle_h
/include headers/parser.rpgle_h
/include headers/interpret.rpgle_h

DCL-DS GLOBAL_SCOPE QUALIFIED DIM(MAX_STATEMENTS) IMPORT;
    id     LIKE(MyString);
    value  LIKE(MyString);
END-DS;


Main();
*INLR = TRUE;
RETURN;



DCL-PROC Main;
    DCL-PI *N;
    END-PI;

    DCL-DS interpreter LIKEDS(Interpreter_t) INZ(*LIKEDS);
    DCL-DS lexer LIKEDS(Lexer_t) INZ(*LIKEDS);
    DCL-DS parser LIKEDS(Parser_t) INZ(*LIKEDS);

    DCL-S i UNS(5);
    DCL-S result LIKE(MyString);
    DCL-S text LIKE(MyString);

    DOU text = '';

        text = '';
        DSPLY 'spi> ' '' text;
        IF text = '';
            LEAVE;
        ENDIF;

        lexer = Lexer_Init(text);
        parser = Parser_Init(lexer);
        interpreter = Interpreter_Init(parser);
        result = Interpreter_Interpret(interpreter);

        FOR i = 1 TO %ELEM(GLOBAL_SCOPE);
            IF GLOBAL_SCOPE(i).Id <> '';
                text = GLOBAL_SCOPE(i).Id + ' ' + GLOBAL_SCOPE(i).Value;
                DSPLY text;
            ENDIF;
        ENDFOR;

    ENDDO;

    RETURN;

END-PROC;

