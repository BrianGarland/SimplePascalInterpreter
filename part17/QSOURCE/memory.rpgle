**FREE

CTL-OPT NOMAIN;

/INCLUDE headers/util.rpgle_h
/INCLUDE headers/memory.rpgle_h



DCL-S Stack POINTER DIM(MAX_STACKSIZE) EXPORT;
DCL-S Top   UNS(5) EXPORT;

DCL-S Log LIKE(ShortString) DIM(10000) EXPORT;
DCL-S Last_Log UNS(5) EXPORT;



// Call Stack

DCL-PROC Stack_Init EXPORT;
    DCL-PI *N;
    END-PI;

    CLEAR Stack;
    Top = 0;

    RETURN;

END-PROC;



DCL-PROC Stack_Push EXPORT;
    DCL-PI *N;
        AR   POINTER;
    END-PI;

    IF Top < MAX_STACKSIZE;
        Top += 1;
        Stack(Top) = AR;
    ENDIF;

    RETURN;

END-PROC;



DCL-PROC Stack_Pop EXPORT;
    DCL-PI *N POINTER;
    END-PI;

    DCL-S AR POINTER INZ(*NULL);

    IF Top > 0;
        AR = Stack(Top);
        Stack(Top) = *NULL;
        Top -= 1;
    ENDIF;

    RETURN AR;

END-PROC;



DCL-PROC Stack_Peak EXPORT;
    DCL-PI *N POINTER;
    END-PI;

    IF Top > 0;
        RETURN Stack(Top);
    ELSE;
        RETURN *NULL;
    ENDIF;

END-PROC;



DCL-PROC Stack_Log EXPORT;
    DCL-PI *N;
        Message LIKE(ShortString) CONST;
    END-PI;

    DCL-DS ar LIKEDS(ActivationRecord_t) BASED(p_ar);

    DCL-S m UNS(5);
    DCL-S s UNS(5);

    Last_Log += 1;
    Log(Last_Log) = Message;

    Last_Log += 1;
    Log(Last_Log) = 'CALL STACK';

    FOR s = 1 TO Top;
        p_ar = Stack(s);
        Last_Log += 1;
        Log(Last_Log) = %CHAR(ar.Level) + ': ' + ar.type + ' ' + ar.name;
        FOR m = 1 TO ar.NumMembers;
            Last_Log += 1;
            Log(Last_Log) = '  ' + ar.Members(m).Key + ': ' + ar.Members(m).Value;
        ENDFOR;
    ENDFOR;

    Last_Log += 1;
    Log(Last_Log) = '';
    Last_Log += 1;
    Log(Last_Log) = '';

    RETURN;

END-PROC;



// Activation Record

DCL-PROC ActivationRecord_Init EXPORT;
    DCL-PI *N POINTER;
        Name LIKE(ShortString);
        Type LIKE(ShortString) CONST;
        Level UNS(5) CONST;
    END-PI;

    DCL-DS Self LIKEDS(ActivationRecord_t) BASED(p_Self);

    p_Self = %ALLOC(%SIZE(ActivationRecord_t));

    Self.Name = Name;
    Self.Type = Type;
    Self.Level = Level;
    Self.NumMembers = 0;
    CLEAR Self.Members;

    RETURN p_Self;

END-PROC;



DCL-PROC ActivationRecord_SetItem EXPORT;
    DCL-PI *N;
        p_Self POINTER;
        Key    LIKE(ShortString) CONST;
        Value  LIKE(ShortString) CONST;
    END-PI;

    DCL-DS Self LIKEDS(ActivationRecord_t) BASED(p_Self);

    DCL-S I UNS(5);

    IF Self.NumMembers > 0;
        i = %LOOKUP(Key:Self.Members(*).Key:1:Self.NumMembers);
    ENDIF;

    IF Self.NumMembers = 0 OR i = 0;
        Self.NumMembers += 1;
        i = Self.NumMembers;
    ENDIF;

    Self.Members(i).Key   = Key;
    Self.Members(i).value = Value;

END-PROC;



DCL-PROC ActivationRecord_GetItem EXPORT;
    DCL-PI *N LIKE(ShortString);
        p_Self POINTER;
        Key    LIKE(ShortString) CONST;
    END-PI;

    DCL-DS Self LIKEDS(ActivationRecord_t) BASED(p_Self);

    DCL-S I UNS(5);

    IF Self.NumMembers > 0;
        i = %LOOKUP(Key:Self.Members(*).Key:1:Self.NumMembers);
    ENDIF;

    IF Self.NumMembers = 0 OR  i = 0;
        RETURN '';
    ENDIF;

    RETURN Self.Members(i).Value;

END-PROC;



