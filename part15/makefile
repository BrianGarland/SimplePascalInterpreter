NAME=Simple Pascal Interpreter
BIN_LIB=SPI
SRC_FLR=QSOURCE
DBGVIEW=*SOURCE
TGTRLS=V7R3M0
SHELL=/QOpenSys/usr/bin/qsh

#----------

all: $(BIN_LIB).lib spifm.dspf spi.pgm spi.cmd
	@echo "Built all"

spi.pgm: spifm.dspf util.rpgle lexer.rpgle parser.rpgle symbols.rpgle interpret.rpgle spi.rpgle

util.rpgle: headers/util.rpgle_h

error.rpgle: headers/util.rpgle_h headers/error.rpgle_h

lexer.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h

parser.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h

symbols.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/symbols.rpgle_h

interpret.rpgle: headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/interpret.rpgle_h

spi.rpgle: spifm.dspf headers/stdio.rpgle_h headers/util.rpgle_h headers/error.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/symbols.rpgle_h headers/interpret.rpgle_h

#----------

%.lib:
	-system -qi "CRTLIB LIB($(BIN_LIB)) TEXT('$(NAME)')"
	@touch $@

%.dspf:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$(SRC_FLR)/$*.dspf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QSOURCE) SRCMBR($*) RSTDSP(*YES) TEXT('$(NAME)') REPLACE(*YES)"
	@touch $@

%.cmd:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$(SRC_FLR)/spi.cmd') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system "CRTCMD CMD($(BIN_LIB)/$*) PGM($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QSOURCE) SRCMBR($*) TEXT('$(NAME)') REPLACE(*YES)"
	@touch $@

%.rpgle:
	liblist -a $(BIN_LIB);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('$(SRC_FLR)/$*.rpgle') TEXT('$(NAME)') REPLACE(*YES) DBGVIEW($(DBGVIEW)) TGTRLS($(TGTRLS))"
	@touch $@

%.pgm:
	liblist -a $(BIN_LIB);\
	system "CRTPGM PGM($(BIN_LIB)/$*) ENTMOD($(BIN_LIB)/$*) MODULE(($(BIN_LIB)/*ALL)) TEXT('$(NAME)') REPLACE(*YES) TGTRLS($(TGTRLS))"
	@touch $@

%.rpgle_h:
	# No create command for headers
	@touch $(@F)

#----------

clean:
	-system -qi "CRTLIB LIB($(BIN_LIB)) TEXT('$(NAME)')"
	system "CLRLIB LIB($(BIN_LIB))"
	system "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"
	rm -f *.lib *.rpgle_h *.dspf *.rpgle *.pgm *.cmd

erase:
	-system -qi "DLTLIB LIB($(BIN_LIB))"
