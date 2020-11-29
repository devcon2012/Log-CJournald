#include <systemd/sd-journal.h>         // journald c api
#include <stdio.h>


// https://perldoc.perl.org/perlapi is your friend ..

void *memdup(const void *src, size_t len)
    {
    char *dup = (char *) malloc( len ) ;
    memcpy(dup, src, len) ;
    dup[len] = (char) 0;
    return (void *) dup ;
    }

// create an iovec from an array. the iovec wil point into
// the array entries which will be invalid as the array changes
// But thats ok because we just log this out and then free the
// iovec again.
struct iovec * _new_iovec ( AV * av, int * i)
    {
    SSize_t siz = av_len(av) + 1 ;
    struct iovec * ret = NULL;

    *i = siz ;
    ret = malloc( siz*sizeof(struct iovec)) ;

    if ( ! ret )
        croak("out of memory") ;

    struct iovec * cursor = ret ;

    for ( SSize_t j=0; j<siz; j++  )
        {
        SV** svp = av_fetch(av, j,1) ;
        if ( svp )
            {
            STRLEN key_len ;
            char * key = SvPVbyte(*svp, key_len) ;
            cursor->iov_base = (void *) key ;
            cursor->iov_len  = (size_t) key_len ;
            cursor++ ;
            }
        }
    return ret ;
    }

// just free the iovec. overkill right now, but we might want
// to do more cleanup later.
void _delete_iovec ( struct iovec * v )
    {
    free ( v ) ;
    return ;
    }


SV * perl_wrap(const char* class, void * pointer)
    {
    if ( ! pointer )
        croak ("cannot wrap NULL") ;

    SV * obj = sv_setref_pv(newSV(0), class, pointer);
    if ( ! obj )
        {
        croak("not enough memory") ;
        }
    //fprintf ( stderr, ">> %ld\n", (long int) pointer ) ;
    SvREADONLY_on(SvRV(obj));
    return obj;
    }

#define perl_unwrap(class, typename, obj) \
  ((typename) __perl_unwrap(__FILE__, __LINE__, (class), (obj)))

 void * __perl_unwrap ( const char* file,
                        int line,
                        const char* class,
                        SV* obj)
    {
    if (!(sv_isobject(obj) && sv_isa(obj, class)))
        {
        croak("%s:%d:perl_unwrap: got an invalid "
                "Perl argument (expected an object blessed "
                "in class ``%s'')", file, line, (class));
        }
    void * pointer = (void *)SvIV(SvRV(obj));
    return pointer ;
    }
