**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/error.rpgle_h



//--------------------------------------
// Error
//--------------------------------------

DCL-PROC Error_Init EXPORT;
    DCL-PI *N LIKEDS(Error_t);
        error_code LIKE(ShortString) VALUE;
        token      LIKE(ShortString) VALUE;
        message    LIKE(ShortString) VALUE;
    END-PI;

    DCL-DS self LIKEDS(Error_t) INZ(*LIKEDS);

    self.error_code = error_code;
    self.token      = token;
    self.message    = message;

    RETURN self;

END-PROC;





