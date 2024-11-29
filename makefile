NAME=Simple Pascal Interpreter
BIN_LIB=BJGARLAND2
SRC_FLR=QSOURCE
DBGVIEW=*SOURCE
TGTRLS=V7R3M0
SHELL=/QOpenSys/usr/bin/qsh

#----------

all: spifm.dspf spi.pgm spi.cmd
	@echo "Built all"

spi.pgm: spifm.dspf util.rpgle error.rpgle memory.rpgle lexer.rpgle parser.rpgle symbols.rpgle interpret.rpgle spi.rpgle

util.rpgle: headers/util.rpgle_h

error.rpgle: headers/util.rpgle_h headers/error.rpgle_h

memory.rpgle: headers/util.rpgle_h headers/memory.rpgle_h

lexer.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h

parser.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h

symbols.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/symbols.rpgle_h

interpret.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/memory.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/interpret.rpgle_h

spi.rpgle: spifm.dspf headers/stdio.rpgle_h headers/util.rpgle_h headers/error.rpgle_h headers/memory.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/symbols.rpgle_h headers/interpret.rpgle_h

#----------

%.dspf:
	system -s "CHGATR OBJ('./$(SRC_FLR)/$*.dspf') ATR(*CCSID) VALUE(819)"
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$(SRC_FLR)/$*.dspf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QSOURCE) SRCMBR($*) RSTDSP(*YES) TEXT('$(NAME)') REPLACE(*YES)"

%.cmd:
	system -s "CHGATR OBJ('./$(SRC_FLR)/$*.cmd') ATR(*CCSID) VALUE(819)"
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$(SRC_FLR)/$*.cmd') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system "CRTCMD CMD($(BIN_LIB)/$*) PGM($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QSOURCE) SRCMBR($*) TEXT('$(NAME)') REPLACE(*YES)"

%.rpgle:
	system -s "CHGATR OBJ('./$(SRC_FLR)/$*.rpgle') ATR(*CCSID) VALUE(819)"
	liblist -a $(BIN_LIB);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('$(SRC_FLR)/$*.rpgle') TEXT('$(NAME)') REPLACE(*YES) DBGVIEW($(DBGVIEW)) TGTRLS($(TGTRLS))"

%.pgm:
	liblist -a $(BIN_LIB);\
	system "CRTPGM PGM($(BIN_LIB)/$*) ENTMOD($(BIN_LIB)/$*) MODULE(($(BIN_LIB)/*ALL)) TEXT('$(NAME)') REPLACE(*YES) TGTRLS($(TGTRLS))"
