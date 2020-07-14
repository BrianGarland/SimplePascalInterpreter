**FREE

/include headers/util.rpgle_h
/include headers/lexer.rpgle_h
/include headers/parser.rpgle_h
/include headers/interpret.rpgle_h

Main();
*INLR = TRUE;
RETURN;



DCL-PROC Main;
    DCL-PI *N;
    END-PI;

    DCL-DS interpreter LIKEDS(Interpreter_t) INZ(*LIKEDS);
    DCL-DS lexer LIKEDS(Lexer_t) INZ(*LIKEDS);
    DCL-DS parser LIKEDS(Parser_t) INZ(*LIKEDS);

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
        DSPLY result;

    ENDDO;

    RETURN;

END-PROC;

