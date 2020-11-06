TARGET=ally
OBJECTS=main.o d6502.o
#OBJECTS=main.o
COREDIR=core
LIBCORE=$(COREDIR)/libcore.a
LIBCORE_TEST=$(COREDIR)/libcore-test.a

CC=gcc
CFLAGS=-O0 -g -Wall `sdl2-config --cflags`
#CFLAGS=-O2 -Wall -DRELEASE `sdl2-config --cflags`
LIBS=`sdl2-config --libs`

#all: $(TARGET) test-cpu

$(TARGET): $(LIBCORE) $(OBJECTS)
	@echo Linking executable $@
	@$(CC) -o $@ $(OBJECTS) $(LIBCORE) $(LIBS)

main.o: main.c core.h
	@echo Compiling $<
	@$(CC) $(CFLAGS) -c $< -o $@

d6502.o: d6502.c
	@echo Compiling $<
	@$(CC) $(CFLAGS) -c $< -o $@

$(LIBCORE): $(COREDIR)
	@$(MAKE) -C $(COREDIR)

clean:
	@rm -f $(TARGET) $(OBJECTS)
	@$(MAKE) -C $(COREDIR) clean

test-cpu: $(LIBCORE_TEST) test-cpu.o
	@echo Linking executable $@
	@$(CC) -o $@ test-cpu.o $(LIBCORE_TEST)

test-cpu.o: test-cpu.c core.h test-cpu.h
	@echo Compiling $<
	@$(CC) $(CFLAGS) -c $< -o $@


