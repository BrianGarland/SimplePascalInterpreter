PROGRAM Main;
   VAR b, x, y : REAL;
   VAR z : INTEGER;

   PROCEDURE AlphaA(a : INTEGER);
      VAR b : INTEGER;

      PROCEDURE Beta(c : INTEGER);
         VAR y : INTEGER;

         PROCEDURE Gamma(c : INTEGER);
            VAR x : INTEGER;
         BEGIN { Gamma }
            x := a + b + c + x + y + z;
         END;  { Gamma }

      BEGIN { Beta }

      END;  { Beta }

   BEGIN { AlphaA }

   END;  { AlphaA }

   PROCEDURE AlphaB(a : INTEGER);
      VAR c : REAL;
   BEGIN { AlphaB }
      c := a + b;
   END;  { AlphaB }

BEGIN { Main }
END.  { Main }