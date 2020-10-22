AR=ar
ASM=nasm
OBJECTS=data.o riot.o banks.o cpu.o tia.o frame.o
OBJECTS_TEST=data.o banks-test.o cpu.o

all: libcore.a libcore-test.a

libcore.a: $(OBJECTS)
	@echo Generating static library $@
	@$(AR) rcs $@ $(OBJECTS)

libcore-test.a: $(OBJECTS_TEST)
	@echo Generating static library $@
	@$(AR) rcs $@ $(OBJECTS_TEST)

%.o: %.asm
	@echo Assembling $<
#	@$(ASM) -felf64 -DRELEASE $<
	@$(ASM) -felf64 -g $<

clean:
	@rm -f *.a *.o
