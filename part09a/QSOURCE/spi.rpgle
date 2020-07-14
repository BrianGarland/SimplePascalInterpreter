**FREE

/include headers/ifs.rpgle_h
/include headers/util.rpgle_h
/include headers/lexer.rpgle_h
/include headers/parser.rpgle_h
/include headers/interpret.rpgle_h

DCL-DS GLOBAL_SCOPE QUALIFIED DIM(MAX_STATEMENTS) IMPORT;
    id     LIKE(ShortString);
    value  LIKE(ShortString);
END-DS;

DCL-PR SPI;
    SourceFile CHAR(100);
END-PR;

DCL-PI SPI;
    SourceFile CHAR(100);
END-PI;

Main(SourceFile);
*INLR = TRUE;
RETURN;



DCL-PROC Main;
    DCL-PI *N;
        SourceFile CHAR(100);
    END-PI;

    DCL-DS interpreter LIKEDS(Interpreter_t) INZ(*LIKEDS);
    DCL-DS lexer LIKEDS(Lexer_t) INZ(*LIKEDS);
    DCL-DS parser LIKEDS(Parser_t) INZ(*LIKEDS);

    DCL-S i UNS(10);
    DCL-S mode VARCHAR(512) INZ('r, crln=N');
    DCL-S result LIKE(ShortString);
    DCL-S handle INT(10);
    DCL-S ReadLength INT(10);
    DCL-S buffer CHAR(1000);
    DCL-S text LIKE(LongString);

    Handle = open(%TRIMR(SourceFile):O_RDONLY+O_TEXTDATA:S_IRGRP);
    IF Handle < 0;
        RETURN;
    ENDIF;
    DOU ReadLength = 0;
        ReadLength = read(Handle:%ADDR(Buffer):%SIZE(Buffer));
        IF ReadLength > 0;
            text += %TRIM(Buffer);
        ENDIF;
    ENDDO;
    CALLP close(Handle);

    lexer = Lexer_Init(text);
    parser = Parser_Init(lexer);
    interpreter = Interpreter_Init(parser);
    result = Interpreter_Interpret(interpreter);

    FOR i = 1 TO %ELEM(GLOBAL_SCOPE);
        IF GLOBAL_SCOPE(i).Id <> '';
            result = GLOBAL_SCOPE(i).Id + ' ' + GLOBAL_SCOPE(i).Value;
            DSPLY result;
        ENDIF;
    ENDFOR;

    RETURN;

END-PROC;

