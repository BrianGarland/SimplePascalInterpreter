             CMD        PROMPT('Simple Pascal Interpreter')
             PARM       KWD(SHOWSCOPE) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*NO) VALUES(*YES *NO) CHOICE(*VALUES) +
                          PROMPT('Show scope information')
             PARM       KWD(SHOWSTACK) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*NO) VALUES(*YES *NO) CHOICE(*VALUES) +
                          PROMPT('Show call stack')
