#!/usr/bin/perl

use strict ;
use warnings ;

use Data::Dumper ;
use Carp ;

use Log::CJournalD qw(:all) ;

my ($handle, $cursor, $data ) ;

sd_journal_open( \$handle, SD_JOURNAL_LOCAL_ONLY)
    and carp ( "cannot open journal" ) ;

sd_journal_next ( $handle )
    or carp ( "cannot seek journal handle" ) ;

sd_journal_enumerate_data( $handle, \$data )
    or carp ( "cannot enumerate" ) ;

sd_journal_getv ( $handle, \$data )
    and carp ( "cannot getv" ) ;

$data = '' ;
my $count = 0 ;
#while ( 0 == sd_journal_getv ( $handle, \$data ) )
while ( 0 == sd_journal_get_data ( $handle, 'MESSAGE', \$data ) )
    {
    print "$data:" . Dumper ( $data ) ;
    $count++ ;
    sd_journal_next ( $handle )
        or last ;
    }
print "Entries: $count\n" ;

my $errc = sd_journal_get_cursor ( $handle, \$cursor ) ;
print STDERR "4E $errc: " . Dumper($cursor) ;
