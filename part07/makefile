NAME=Simple Pascal Interpreter
BIN_LIB=SPI
DBGVIEW=*SOURCE
TGTRLS=V7R3M0
SHELL=/QOpenSys/usr/bin/qsh

#----------

all: spi.pgm

spi.pgm: interpret.mod lexer.mod parser.mod spi.mod

lexer.mod: headers/util.rpgle_h headers/lexer.rpgle_h

parser.mod: headers/util.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h

interpret.mod: headers/util.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/interpret.rpgle_h

spi.mod: headers/stdio.rpgle_h headers/util.rpgle_h headers/lexer.rpgle_h headers/parser.rpgle_h headers/symbols.rpgle_h headers/interpret.rpgle_h

#----------

%.mod: %.rpgle
	liblist -a $(BIN_LIB);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('$*.rpgle') TEXT('$(NAME)') REPLACE(*YES) DBGVIEW($(DBGVIEW)) TGTRLS($(TGTRLS))"

%.pgm:
	liblist -a $(BIN_LIB);\
	system "CRTPGM PGM($(BIN_LIB)/$*) ENTMOD($(BIN_LIB)/$*) MODULE(($(BIN_LIB)/*ALL)) TEXT('$(NAME)') REPLACE(*YES) TGTRLS($(TGTRLS))"
	
%.rpgle_h:
	# No create command for headers

#----------

clean:
	-system -qi "CRTLIB LIB($(BIN_LIB)) TEXT('$(NAME)')"
	system "CLRLIB LIB($(BIN_LIB))"
	system "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) RCDLEN(112)"

erase:
	-system -qi "DLTLIB LIB($(BIN_LIB))"
