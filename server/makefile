CFLAGS+= -g -Wall

CC = $(CROSS_COMPILE)gcc $(CFLAGS)

all: aesdsocket.o aesdsocket

aesdsocket.o : aesdsocket.c
	    $(CC) -c -o aesdsocket.o aesdsocket.c

aesdsocket : 
		 $(CC) aesdsocket.o -o aesdsocket

.PHONY : clean        
clean :
		rm -rf aesdsocket.o aesdsocket
