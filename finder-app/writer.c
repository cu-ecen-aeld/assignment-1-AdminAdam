#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>

int main (int argc, char **argv) {

    openlog(NULL,0,LOG_USER);

    if (argc < 3 ) {
        syslog(LOG_ERR, "Too few arguments");
        exit(1);        
    }

    FILE* ptr;
    
    ptr = fopen(argv[1], "w+");
    
    if (ptr == NULL) {
        syslog(LOG_ERR, "Unale to open file %s", argv[1]);
        exit(1);        
    }
    
    syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
    
    fputs(argv[2], ptr);
    
    fclose(ptr);
    
    return 0;
}
