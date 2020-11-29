#include <stdio.h>
#include <string.h>
#include <systemd/sd-journal.h>

int main1(int argc, char *argv[]) {
    int r;
    sd_journal *j;
    r = sd_journal_open(&j, SD_JOURNAL_LOCAL_ONLY);
    if (r < 0) {
    fprintf(stderr, "Failed to open journal: %s\n", strerror(-r));
    return 1;
    }
    SD_JOURNAL_FOREACH(j) {
    const char *d;
    size_t l;

    r = sd_journal_get_data(j, "MESSAGE", (const void **)&d, &l);
    if (r < 0) {
        fprintf(stderr, "Failed to read message field: %s\n", strerror(-r));
        continue;
    }

    printf("%.*s\n", (int) l, d);
    }
    sd_journal_close(j);
    return 0;
}


int main ( int argc, char **argv)
    {

    sd_journal * phandle = NULL ;
    int nret = sd_journal_open ( &phandle, SD_JOURNAL_LOCAL_ONLY ) ;
    printf("1R: %d P:%d\n", nret, (int) phandle ) ;

    nret = sd_journal_next ( phandle ) ;
    printf("2R: %d P:%d\n", nret, (int) phandle ) ;

    const char *data = NULL ;
    size_t len = 0;

    sd_journal_restart_data ( phandle ) ;
    nret = sd_journal_enumerate_data(phandle, &data, &len);
    printf("2R: %d P:%d %d %s\n", nret, (int) data, len, data ) ;

    while ( (nret = sd_journal_get_data ( phandle, "MESSAGE", (void *) &data, &len ) ) == 0 )
        {
        printf("3R: %d D:%d %s\n", nret, len, data ) ;
        nret = sd_journal_next ( phandle ) ;
        printf("2R: %d P:%d\n", nret, (int) phandle ) ;
        if ( nret == 0)
            break ;
        }

    char * cursor = NULL ;
    nret = sd_journal_get_cursor ( phandle, &cursor ) ;
    printf("4R: %d P:%s\n", nret, cursor ? cursor : "" ) ;
    }

