NAME=Simple Pascal Interpreter
BIN_LIB=SPI
DBGVIEW=*SOURCE
TGTRLS=V7R3M0
SHELL=/QOpenSys/usr/bin/qsh

#----------

all:                  
	liblist -a $(BIN_LIB);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/CALC5) SRCSTMF('calc5.rpgle') TEXT('$(NAME)') REPLACE(*YES) DBGVIEW($(DBGVIEW)) TGTRLS($(TGTRLS))"
	system "CRTPGM PGM($(BIN_LIB)/CALC5) ENTMOD($(BIN_LIB)/CALC5) MODULE($(BIN_LIB)/CALC5) TEXT('$(NAME)') REPLACE(*YES) TGTRLS($(TGTRLS))"

#----------

clean:
	-system -qi "CRTLIB LIB($(BIN_LIB)) TEXT('$(NAME)')"
	system "CLRLIB LIB($(BIN_LIB))"
	system "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"

erase:
	-system -qi "DLTLIB LIB($(BIN_LIB))"
	