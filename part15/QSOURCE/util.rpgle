**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h



DCL-PROC isAlpha EXPORT;
    DCL-PI *N IND;
        Test_Char CHAR(1);
    END-PI;

    DCL-C ALPHA 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

    RETURN (%SCAN(Test_Char:Alpha) <> 0);

END-PROC;



DCL-PROC isAlNum EXPORT;
    DCL-PI *N IND;
        Test_Char CHAR(1);
    END-PI;

    RETURN (isAlpha(Test_Char) OR isDigit(Test_Char));

END-PROC;



DCL-PROC isDigit EXPORT;
    DCL-PI *N IND;
        Test_Char CHAR(1);
    END-PI;

    DCL-C DIGITS '0123456789';

    RETURN (%SCAN(Test_Char:Digits) <> 0);

END-PROC;



DCL-PROC isSpace EXPORT;
    DCL-PI *N IND;
        Test_Char CHAR(1);
    END-PI;

    // space, cr, lf, tab
    DCL-C WhiteSpace x'400D2505';

    RETURN (%SCAN(Test_Char:WhiteSpace) <> 0);

END-PROC;



DCL-PROC toUpper EXPORT;
    DCL-PI *N LIKE(ShortString);
        Input LIKE(ShortString) CONST;
    END-PI;

    DCL-C LOWER 'abcdefghijklmnopqrstuvwxyz';
    DCL-C UPPER 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    RETURN %XLATE(LOWER:UPPER:Input);

END-PROC;

