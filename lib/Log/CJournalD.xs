#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <systemd/sd-journal.h>         // journald c api
#include "journaldapihelper.h"
#include "journaldapihelper.c"

#define HANDLE_CLASS "Log::CJournalD::handle"
#define CURSOR_CLASS "Log::CJournalD::cursor"

// additional c code goes here

MODULE = Log::CJournalD  PACKAGE = Log::CJournalD
PROTOTYPES: ENABLE

# XS code

int
_SD_JOURNAL_LOCAL_ONLY ()
  CODE:
    RETVAL = SD_JOURNAL_LOCAL_ONLY ;
  OUTPUT:
    RETVAL

int
_SD_JOURNAL_RUNTIME_ONLY ()
  CODE:
    RETVAL = SD_JOURNAL_RUNTIME_ONLY ;
  OUTPUT:
    RETVAL

int
_SD_JOURNAL_SYSTEM ()
  CODE:
    RETVAL = SD_JOURNAL_SYSTEM ;
  OUTPUT:
    RETVAL

int
_SD_JOURNAL_OS_ROOT ()
  CODE:
    RETVAL = SD_JOURNAL_OS_ROOT ;
  OUTPUT:
    RETVAL

int
_SD_JOURNAL_CURRENT_USER ()
  CODE:
    RETVAL = SD_JOURNAL_CURRENT_USER ;
  OUTPUT:
    RETVAL

# int sd_journal_print( int priority, const char *format, … ) ;
int
_sd_journal_print ( priority, data )
  int priority
  const char * data
  CODE:
    RETVAL = sd_journal_print ( priority, "%s", data ) ;
  OUTPUT:
    RETVAL

int
_sd_journal_sendv ( av )
  AV * av
  CODE:
    int nv =0;
    struct iovec *v = _new_iovec ( av, &nv ) ;
    RETVAL = sd_journal_sendv ( v, nv ) ;
    _delete_iovec ( v ) ;
  OUTPUT:
    RETVAL

int
_sd_journal_perror ( data )
  const char * data
  CODE:
    RETVAL = sd_journal_perror ( data ) ;
  OUTPUT:
    RETVAL

AV *
_sd_journal_open( flags )
  int flags
  PREINIT:
    sd_journal  * phandle = NULL ;
    SV          * handle  = NULL ;
    int           nerr    = 0 ;
  CODE:
    nerr = sd_journal_open ( &phandle, flags ) ;
    handle = perl_wrap(HANDLE_CLASS, phandle) ;
    RETVAL = (AV*)sv_2mortal((SV*)newAV());
    av_push(RETVAL, newSVsv( handle ));
    av_push(RETVAL, newSViv( nerr ));
  OUTPUT:
    RETVAL

AV *
_sd_journal_open_directory( path, flags )
  char * path
  int flags
  PREINIT:
    sd_journal  * phandle = NULL ;
    SV          * handle  = NULL ;
    int           nerr    = 0 ;
  CODE:
    nerr = sd_journal_open_directory ( &phandle, path, flags ) ;
    handle = perl_wrap(HANDLE_CLASS, phandle) ;
    RETVAL = (AV*)sv_2mortal((SV*)newAV());
    av_push(RETVAL, newSVsv( handle ));
    av_push(RETVAL, newSViv( nerr ));
  OUTPUT:
    RETVAL

void
_sd_journal_close( handle )
  SV * handle
  CODE:
    sd_journal * phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    sd_journal_close ( phandle ) ;

AV *
_sd_journal_get_cursor( handle )
  SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
    char        * pcursor = NULL ;
    SV          * cursor  = NULL ;
    int           nerr    = 0 ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    nerr = sd_journal_get_cursor ( phandle, &pcursor ) ;
    if ( pcursor )
        {
        cursor = newSVpv(pcursor, strlen(pcursor) ) ;
        }
    else
      croak ("got no cursor") ;
    RETVAL = (AV*)sv_2mortal((SV*)newAV());
    if ( cursor )
      {
      av_push(RETVAL, cursor ) ;
      }
    else
      av_push(RETVAL, newSVpv("", 1 ) );

    av_push(RETVAL, newSViv( nerr ));
  OUTPUT:
    RETVAL

int
_sd_journal_test_cursor( handle, cursor )
  SV * handle
  char * cursor
  PREINIT:
    sd_journal  * phandle = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    RETVAL  = sd_journal_test_cursor ( phandle, cursor ) ;
  OUTPUT:
    RETVAL

int
_sd_journal_next( handle )
SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    RETVAL  = sd_journal_next(phandle) ;
  OUTPUT:
    RETVAL

int
_sd_journal_previous( handle )
SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    RETVAL  = sd_journal_previous(phandle) ;
  OUTPUT:
    RETVAL

int
_sd_journal_seek_head( handle )
SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    RETVAL  = sd_journal_seek_head(phandle) ;
  OUTPUT:
    RETVAL

int
_sd_journal_seek_tail( handle )
SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    RETVAL  = sd_journal_seek_tail(phandle) ;
  OUTPUT:
    RETVAL

int
_sd_journal_seek_cursor( handle, cursor )
SV * handle
SV * cursor
  PREINIT:
    sd_journal  * phandle = NULL ;
    char        * pcursor = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    pcursor = SvPVbyte_nolen(cursor) ;
    RETVAL  = sd_journal_seek_cursor(phandle, pcursor) ;
  OUTPUT:
    RETVAL

AV *
_sd_journal_get_data( handle, field)
SV * handle
char * field
  PREINIT:
    sd_journal  * phandle = NULL ;
    SV          * data    = NULL ;
    int           nerr    = 0 ;
    size_t        length  = 0 ;
    const void  * pdata   = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    nerr = sd_journal_get_data(phandle, field, &pdata, &length);
    RETVAL = (AV*)sv_2mortal((SV*)newAV());
    if ( pdata && (nerr == 0) )
      {
      //data = newSVpv(memdup(pdata, length), length ) ;
      data = newSVpv(pdata, length ) ;
      av_push(RETVAL, newSVsv( data )) ;
      }
    else
      {
      av_push(RETVAL, newSVpv("", 1 ) );
      }
    av_push(RETVAL, newSViv( nerr )) ;
  OUTPUT:
    RETVAL

AV *
_sd_journal_enumerate_data( handle )
SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
    SV          * data    = NULL ;
    int           nerr    = 0 ;
    size_t        length  = 0 ;
    const void  * pdata   = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    nerr = sd_journal_enumerate_data(phandle, &pdata, &length);

    RETVAL = (AV*)sv_2mortal((SV*)newAV());
    if ( pdata && (nerr == 1) )
      {
      //data = newSVpv(memdup(pdata, length), length ) ;
      data = newSVpv(pdata, length ) ;
      av_push(RETVAL, newSVsv( data )) ;
      }
    else
      {
      av_push(RETVAL, newSVpv("", 1 ) );
      }
    av_push(RETVAL, newSViv( nerr )) ;
  OUTPUT:
    RETVAL

void
sd_journal_restart_data( handle )
SV * handle
  PREINIT:
    sd_journal  * phandle = NULL ;
  CODE:
    phandle = perl_unwrap(HANDLE_CLASS, sd_journal *, handle) ;
    sd_journal_restart_data(phandle) ;

