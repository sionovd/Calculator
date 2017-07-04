all: calc.bin

calc.bin: calc.o
	gcc -m32 -Wall -g calc.o -o calc.bin

calc.o: calc.s
	nasm -f elf calc.s -o calc.o
 
clean:
	rm -f calc.o calc.bin