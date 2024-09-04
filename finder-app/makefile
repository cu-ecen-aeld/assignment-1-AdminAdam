
ifdef CROSS_COMPILE
COMPILER=aarch64-none-linux-gnu-gcc
else
COMPILER=gcc
endif

CFLAGS+=-Wall

default : 
		 $(COMPILER) $(CFLAGS) writer.c -o writer

.PHONY : clean        
clean :
		-rm writer
