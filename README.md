# Simple Pascal Interpreter for IBM i

This is my attempt to use RPGLE to create a Pascal Interpreter.  

I'm following Ruslan Spivak's blog posts where he does this in Python.  

[Ruslan's Blog](https://ruslanspivak.com/lsbasi-part1/)

[Ruslan's github](https://github.com/rspivak/lsbasi)


### Installation 

1. `git clone` this repository
2. `cd partxx` (change to directory you want to build)
2. `gmake` (available from yum)

### Usage instructions

1. `ADDLIBLE SPI` (or whatever library you used)
2. Depending on which part you are running
	1. For parts 1 to 6: `CALL PARTxx`
	2. For parts 7 and 8: `SPI` 
	3. For part 9 (use part09a folder): `SPI xxxxxx` where xxxxx is the path to the Pascal file 

### License

MIT License. See file `LICENSE` in root of this repository.
