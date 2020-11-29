#include <systemd/sd-journal.h>
struct iovec * _new_iovec ( AV *, int * ) ;
void _delete_iovec ( struct iovec * v ) ;
void *memdup(const void *src, size_t len) ;
#define JOURNAL_HANDLE "JOURNAL"