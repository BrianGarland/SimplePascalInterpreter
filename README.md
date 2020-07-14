# Simple Pascal Interpreter for IBM i

This is my attempt to use RPGLE to create a Pascal Interpreter.  

I'm following Ruslan Spivak's blog posts where he does this in Python.  

[Ruslan's Blog](https://ruslanspivak.com/lsbasi-part1/)

[Ruslan's github](https://github.com/rspivak/lsbasi)

Starting in part 9 I worked on a UI for the interpreter. 

### Installation 

1. `git clone` this repository
2. `cd partxx` (change to directory you want to build)
2. `gmake` (available from yum)

### Usage instructions

1. `ADDLIBLE SPI` (or whatever library you used)
2. Depending on which part you are running
	1. Parts 1 to 6: `CALL PARTxx`
	2. Parts 7 and 8: `SPI` 
	3. Part 9 (use part09a folder): `SPI xxxxxx` where xxxxx is the path to the Pascal file 
	4. Part 10 and up: `SPI` and then use function keys to load and run your Pascal file

### License

MIT License. See file `LICENSE` in root of this repository.
