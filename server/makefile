all: aesdsocket.o aesdsocket

aesdsocket.o : aesdsocket.c
		$(CC) $(CCFLAGS) -Wall -Werror -c  aesdsocket.c

aesdsocket : 
		$(CC) $(LDFLAGS) -Wall -Werror aesdsocket.o -o aesdsocket

.PHONY : clean        
clean :
		rm -rf aesdsocket.o aesdsocket
