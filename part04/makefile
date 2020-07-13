NAME=Simple Pascal Interpreter
BIN_LIB=SPI
SRC_FLR=QSOURCE
DBGVIEW=*SOURCE
TGTRLS=V7R3M0
SHELL=/QOpenSys/usr/bin/qsh

#----------

all: calc4.rpgle calc4.pgm

#----------

%.rpgle:
	liblist -a $(BIN_LIB);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('$(SRC_FLR)/$*.rpgle') TEXT('$(NAME)') REPLACE(*YES) DBGVIEW($(DBGVIEW)) TGTRLS($(TGTRLS))"

%.pgm:
	liblist -a $(BIN_LIB);\
	system "CRTPGM PGM($(BIN_LIB)/$*) ENTMOD($(BIN_LIB)/$*) MODULE(($(BIN_LIB)/*ALL)) TEXT('$(NAME)') REPLACE(*YES) TGTRLS($(TGTRLS))"

#----------

clean:
	-system -qi "CRTLIB LIB($(BIN_LIB)) TEXT('$(NAME)')"
	system "CLRLIB LIB($(BIN_LIB))"
	system "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"

erase:
	-system -qi "DLTLIB LIB($(BIN_LIB))"
	