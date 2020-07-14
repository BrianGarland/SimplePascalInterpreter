      //
      // The UI portion of a Simple Pascal Interpreter for IBM i
      //
      // Copyright 2020, Brian J Garland
      //

     FSPIFM     CF   E             WORKSTN  INFDS(DSPFDS)

      /include headers/stdio.rpgle_h
      /include headers/util.rpgle_h
      /include headers/lexer.rpgle_h
      /include headers/parser.rpgle_h
      /include headers/interpret.rpgle_h
      /include headers/symbols.rpgle_h

     D GLOBAL_SCOPE    DS                  QUALIFIED DIM(MAX_STATEMENTS) IMPORT
     D  id                                 LIKE(ShortString)
     D  value                              LIKE(ShortString)

     D SymbolTable     DS                  LIKEDS(SymbolTable_t) IMPORT

     D #EXIT           C                   x'33'                                F3
     D #RUN            C                   x'38'                                F8
     D #LIST           C                   x'39'                                F9
     D #LOAD           C                   x'3A'                                F10
     D #SAVE           C                   x'3B'                                F11
     D #CANCEL         C                   x'3C'                                F12
     D #TOP            C                   x'B5'                                F17
     D #BOTTOM         C                   x'B6'                                F18
     D #PAGEUP         C                   X'F4'                                Page Up
     D #PAGEDOWN       C                   X'F5'                                Page Down

     D Offset          C                   2

     D NULL            C                   x'00'
     D CR              C                   x'0D'
     D LF              C                   x'25'

     D DSPFDS          DS
     D  FKey                          1A   OVERLAY(DSPFDS:369)

     D LineDS          DS
     D  Line01
     D  Line02
     D  Line03
     D  Line04
     D  Line05
     D  Line06
     D  Line07
     D  Line08
     D  Line09
     D  Line10
     D  Line11
     D  Line12
     D  Line13
     D  Line14
     D  Line15
     D  Line16
     D  Line17
     D  Line18
     D  Line19
     D  Line20
     D  Line21
     D  Line22
     D  Line23
     D  Line24
     D  Line                               LIKE(Line01) DIM(24)
     D                                     OVERLAY(LineDS:1)

     D Listing         DS                  DIM(1000) QUALIFIED
     D  Line#                         5S 0 INZ(0)
     D  Statement                          LIKE(Line01) INZ('')

     D AllDone         S               N   INZ(*OFF)
     D CurrentLine     S              5U 0
     D History         S                   LIKE(Line01) DIM(10000)
     D HistoryLines    S              5U 0 INZ(0)
     D I               S              5U 0
     D J               S              5U 0
     D ListingLines    S              5U 0 INZ(0)

      /FREE

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

      /END-FREE



      //------------------------------------------------------------------------
     P FindBottom      B
      //------------------------------------------------------------------------
     D FindBottom      PI

      /FREE

       IF HistoryLines > %ELEM(Line) - 2;
           CurrentLine = HistoryLines - (%ELEM(Line) - 2) + 1;
       ELSE;
           CurrentLine = 1;
       ENDIF;

       RETURN;

      /END-FREE

     P FindBottom      E



      //------------------------------------------------------------------------
     P Center1         B
      //------------------------------------------------------------------------
     D Center1         PI                  LIKE(Title1)
     D  StringIn                           LIKE(Title1) CONST

     D Pos             S              5U 0
     D StringOut       S                   LIKE(Title1) INZ

      /FREE

       Pos = (%SIZE(StringOut)/2+1) - (%LEN(%TRIM(StringIn))/2);
       %SUBST(StringOut:Pos) = %TRIM(StringIn);
       RETURN StringOut;

      /END-FREE

     P Center1         E



      //------------------------------------------------------------------------
     P Center3         B
      //------------------------------------------------------------------------
     D Center3         PI                  LIKE(Title3)
     D  StringIn                           LIKE(Title3) CONST

     D Pos             S              5U 0
     D StringOut       S                   LIKE(Title3) INZ

      /FREE

       Pos = (%SIZE(StringOut)/2+1) - (%LEN(%TRIM(StringIn))/2);
       %SUBST(StringOut:Pos) = %TRIM(StringIn);
       RETURN StringOut;

      /END-FREE

     P Center3         E



      //------------------------------------------------------------------------
     P UpdateListing   B
      //------------------------------------------------------------------------
     D UpdateListing   PI
     D  InputLine                          LIKE(Input)

     D Index           S              5S 0 INZ(0)
     D Line#           S              5S 0 INZ(0)
     D Separator       S              5U 0 INZ(0)
     D Statement       S                   LIKE(Line01) INZ('')

      /FREE

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

      /END-FREE

     P UpdateListing   E



      //------------------------------------------------------------------------
     P RunFile         B
      //------------------------------------------------------------------------
     D RunFile         PI

     D interpreter     DS                  LIKEDS(Interpreter_t) INZ(*LIKEDS)
     D lexer           DS                  LIKEDS(Lexer_t) INZ(*LIKEDS)
     D parser          DS                  LIKEDS(Parser_t) INZ(*LIKEDS)

     D i               S              5U 0
     D p_Tree          S               *
     D Text            S                   LIKE(LongString) INZ('')
     D Result          S                   LIKE(ShortString)

      /FREE

       HistoryLines += 1;
       History(HistoryLines) = '> RUN';

       FOR i = 1 TO ListingLines;
           Text += %TRIMR(Listing(i).Statement) + CR + LF;
       ENDFOR;

       lexer = Lexer_Init(text);
       parser = Parser_Init(lexer);
       p_tree = Parser_Parse(parser);
       SymbolTable_Init();
       SymbolTableBuilder_Visit(p_tree);

       HistoryLines += 1;
       History(HistoryLines) = '';

       HistoryLines += 1;
       History(HistoryLines) = '  Symbol Table:';
       FOR i = 1 TO SymbolTable.NumSymbols;
           result = '{"name":"' + SymbolTable.Symbol(i).name + '"'
                  + ',"category":"' + SymbolTable.Symbol(i).category + '"'
                  + ',"type":"' + SymbolTable.Symbol(i).type + '"}';
           HistoryLines += 1;
           History(HistoryLines) = '    ' + result;
       ENDFOR;

       lexer = Lexer_Init(text);
       parser = Parser_Init(lexer);
       interpreter = Interpreter_Init(parser);
       result = Interpreter_Interpret(interpreter);

       HistoryLines += 1;
       History(HistoryLines) = '';

       HistoryLines += 1;
       History(HistoryLines) = '  Global Variables:';
       FOR i = 1 TO %ELEM(GLOBAL_SCOPE);
           IF GLOBAL_SCOPE(i).Id <> '';
               result = GLOBAL_SCOPE(i).Id + ' = ' + GLOBAL_SCOPE(i).Value;
               HistoryLines += 1;
               History(HistoryLines) = '    ' + result;
           ENDIF;
       ENDFOR;

       RETURN;

      /END-FREE

     P RunFile         E



      //------------------------------------------------------------------------
     P ListFile        B
      //------------------------------------------------------------------------
     D ListFile        PI

      /FREE

       HistoryLines += 1;
       History(HistoryLines) = '> LIST';

       FOR i = 1 TO ListingLines;

           HistoryLines += 1;
           History(HistoryLines) = '  '
                                 + %EDITC(Listing(i).Line#:'X')
                                 + ' ' + Listing(i).Statement;

       ENDFOR;

       RETURN;

      /END-FREE

     P ListFile        E



      //------------------------------------------------------------------------
     P LoadFile        B
      //------------------------------------------------------------------------
     D LoadFile        PI

     D Buffer          S           1000A
     D BufferLen       S              5U 0
     D LoadDone        S               N   INZ(FALSE)
     D Options         S            100A   VARYING
     D Stream          S                   LIKE(pFile)
     D Success         S               *

      /FREE

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

      /END-FREE

     P LoadFile        E



      //------------------------------------------------------------------------
     P SaveFile        B
      //------------------------------------------------------------------------
     D SaveFile        PI

     D Buffer          S           1000A   VARYING
     D Options         S            100A   VARYING
     D SaveDone        S               N   INZ(FALSE)
     D Stream          S                   LIKE(pFile)

      /FREE

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
               Buffer = %TRIMR(%SUBST(Listing(i).Statement:3)) + LF;
               fPuts(Buffer:Stream);
           ENDFOR;

           fClose(Stream);

           HistoryLines += 1;
           History(HistoryLines) = '  ' + %CHAR(ListingLines)
                                 + ' statements saved.';

           SaveDone = TRUE;

       ENDDO;

       RETURN;

      /END-FREE

     P SaveFile        E


