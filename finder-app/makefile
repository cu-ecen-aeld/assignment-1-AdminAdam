CFLAGS+= -g -Wall

CC = $(CROSS_COMPILE)gcc $(CFLAGS)

all: writer.o writer

writer.o : writer.c
	    $(CC) -c -o writer.o writer.c

writer : 
		 $(CC) writer.o -o writer

.PHONY : clean        
clean :
		rm -rf writer.o writer
