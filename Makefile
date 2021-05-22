VPATH = src

BC = bison
BFLAGS = --color=always -Wconflicts-rr -v

CC = clang
CFLAGS = -Wall -std=c11 -g

FC = flex

PC = fpc
PFLAGS = -Miso

JSMC = java -jar ../../jasmin-2.4/jasmin.jar

all: pascal.exe main.exe

doc: Doxyfile
	doxygen $<

test: scripts/smoke_test.pl txt/smoke_test.txt
	perl $^ > test.output 2>&1

pascal.exe: pascal.tab.o pascal.lex.o pascal_funcs.o -lfl -lm
	$(CC) $(CFLAGS) -o $@ $^

main.exe: main.pas
	$(PC) $(PFLAGS) -o$@ $<

Main.class: Main.j
	$(JSMC) $<

Main.j: main.pas pascal.exe
	./pascal.exe $< > $@

%.o: %.c
	$(CC) -c $< -I$(VPATH)

%.tab.c: %.y
	$(BC) $(BFLAGS) -d $<

%.lex.c: %.l
	flex -o$@ $<

.PHONY: clean
clean:
	rm -rfv pascal* *.class *.j *.o* *.exe doc

