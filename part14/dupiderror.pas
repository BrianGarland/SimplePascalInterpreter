PROGRAM Main;
   VAR x, y: REAL;

   PROCEDURE Alpha(a : INTEGER);
      VAR y : INTEGER;
      VAR a : REAL;  { ERROR here! }
   BEGIN
      x := a + x + y;
   END;

BEGIN { Main }

END.  { Main }
