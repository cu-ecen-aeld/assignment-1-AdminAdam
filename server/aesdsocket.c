#include "syslog.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <netdb.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <stdbool.h>

bool sig_caught = false;
int sfd;
struct addrinfo *result;

static void signal_handler(int sig) {
    if( sig == SIGINT) {
        syslog(LOG_NOTICE, "SIGINT received");
        printf("SIGINT received\n");
        sig_caught = true;
        remove("/var/tmp/aesdsocketdata");
        shutdown(sfd,SHUT_RDWR);
        close(sfd);
        freeaddrinfo(result);
    } else if ( sig == SIGTERM ) {
        syslog(LOG_NOTICE, "SIGTERM received");
        printf("SIGTERM received\n");
        sig_caught = true;
        remove("/var/tmp/aesdsocketdata");
        shutdown(sfd,SHUT_RDWR);
        close(sfd);
        freeaddrinfo(result);
    }
}

int main (int argc, char* argv[]) {
    struct addrinfo hints;
    int s, listener, new_fd;
    struct sockaddr_storage peer_addr;
    socklen_t peer_addr_len;
    //ssize_t nread;
    char buf;

    struct sigaction new_action;
    memset(&new_action,0,sizeof(struct sigaction));
    new_action.sa_handler=signal_handler;
    sigaction(SIGTERM, &new_action, NULL);
    sigaction(SIGINT, &new_action, NULL);

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM; /* Datagram socket */
    hints.ai_flags = AI_PASSIVE;    /* For wildcard IP address */
    hints.ai_protocol = 0;          /* Any protocol */
    hints.ai_canonname = NULL;
    hints.ai_addr = NULL;
    hints.ai_next = NULL;

    s = getaddrinfo(NULL, "9000", &hints, &result);
    if (s != 0) {
       fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
       exit(-1);
    }
    printf("getaddrinfo done\n");
    
    sfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sfd == -1) {
        syslog(LOG_ERR, "Socket fd failed");
        exit(-1);
    }
    printf("socket done\n");

    int val = 1;
    int sockoptres = setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &val, sizeof(val));
    if (sockoptres == -1) {
        syslog(LOG_ERR, "sockoptout failed");
        exit(-1);
    }
    printf("setsockopt done\n");

    if (bind(sfd, result->ai_addr, result->ai_addrlen) != 0){
        syslog(LOG_ERR, "Bind failed");
       exit(-1);
    }

    char opt;
	while((opt = getopt(argc, argv, "-d")) != -1)
	{
		if (opt == 'd')
		{
            if (daemon(0, 0) == -1 ) {
                exit(-1);
            }
            //setsid();
        }
	}
    printf("bind done\n");
          
    listener = listen(sfd, 10);
    if (listener == -1) {
        syslog(LOG_ERR, "Listen failed");
       exit(-1);
    }
    printf("listen done\n");
    remove("/var/tmp/aesdsocketdata");
    FILE *file;
    file = fopen("/var/tmp/aesdsocketdata", "w+");
    if (!file) {
        syslog(LOG_ERR, "File didn't open\n");
        printf("File didn't open\n");
        return -1;
    }
    printf("file open done\n");
    char newlinechar;
    memcpy(&newlinechar, "\n", 1);

    peer_addr_len = sizeof(peer_addr);
    
    while (sig_caught == false) {
        printf("While\n");
        new_fd = accept(sfd, (struct sockaddr *)&peer_addr, &peer_addr_len);
        if(new_fd == -1) {
            syslog(LOG_ERR, "Accept connection failed");
            exit(-1);
        }
        
        syslog(LOG_NOTICE, "Accepted connection from %s\n", result->ai_addr->sa_data);
        printf("Accepted connection\n");
        

        int recvRes;
        do {

            recvRes = recv(new_fd, &buf, 1, 0);
            if (recvRes == -1) {
                syslog(LOG_ERR, "Recv failed");
                exit(-1);
            }
            
            fwrite(&buf, sizeof(char), 1, file);
         
        } while(memcmp(&buf, &newlinechar, 1) != 0);
        
        fflush(file);

        char read_buf = 0;
        ssize_t num_read;
        int fseeker = fseek(file, 0, SEEK_SET);
        if (fseeker == -1) {
            return -1;
        }

        do {
            num_read = fread(&read_buf, sizeof(char), 1, file);

            if(feof(file))
                break;

            send(new_fd, &read_buf, 1, 0);
        } while (num_read > 0);


        close(new_fd);
    }
    syslog(LOG_ERR, "Exiting, caught signal");
    printf("Exiting\n");
    fclose(file);
    remove("/var/tmp/aesdsocketdata");
    shutdown(sfd,SHUT_RDWR);
    close(sfd);
    freeaddrinfo(result);

    return 0;

}
