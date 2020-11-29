# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Log-CJournalD.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict ;
use warnings ;
use English ;
use Data::Dumper ;
use Test::More tests => 27 ;
BEGIN { use_ok('Log::CJournalD') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# constants
# SD_JOURNAL_LOCAL_ONLY, SD_JOURNAL_RUNTIME_ONLY, SD_JOURNAL_SYSTEM, SD_JOURNAL_CURRENT_USER, SD_JOURNAL_OS_ROOT
ok( 0 != Log::CJournalD::SD_JOURNAL_LOCAL_ONLY,
       'const SD_JOURNAL_LOCAL_ONLY: ' . Log::CJournalD::SD_JOURNAL_LOCAL_ONLY )  ;
ok( 0 != Log::CJournalD::SD_JOURNAL_RUNTIME_ONLY,
        'const SD_JOURNAL_RUNTIME_ONLY: ' . Log::CJournalD::SD_JOURNAL_RUNTIME_ONLY )  ;
ok( 0 != Log::CJournalD::SD_JOURNAL_SYSTEM,
        'const SD_JOURNAL_SYSTEM: ' . Log::CJournalD::SD_JOURNAL_SYSTEM )  ;
ok( 0 != Log::CJournalD::SD_JOURNAL_CURRENT_USER,
        'const SD_JOURNAL_CURRENT_USER: ' . Log::CJournalD::SD_JOURNAL_CURRENT_USER )  ;
ok( 0 != Log::CJournalD::SD_JOURNAL_OS_ROOT,
        'const SD_JOURNAL_OS_ROOT: ' .  Log::CJournalD::SD_JOURNAL_OS_ROOT )  ;

# logging
ok( 0 == Log::CJournalD::sd_journal_print( 1, "%s", "data" ), 'sd_journal_print 1')  ;
ok( 0 == Log::CJournalD::sd_journal_print( 1, "%i: %s", $$, "data" ), 'sd_journal_print 2')  ;
ok( 0 == Log::CJournalD::sd_journal_send( PRIORITY=>1, MESSAGE => "sd_journal_send 1", KEY1 => "value1" ), 'sd_journal_send 1')  ;
ok( 0 == Log::CJournalD::sd_journal_sendv( {PRIORITY=>1, MESSAGE => "sd_journal_sendv 1", KEY2 => "value2"} ), 'sd_journal_sendv 1')  ;
ok( 0 == Log::CJournalD::sd_journal_perror( "perror tst" ), 'sd_journal_perror 1')  ;

SKIP:
        {
        skip "Accessing the log requires root priviledges", 16
                if ( $EFFECTIVE_USER_ID > 0 ) ;
        # accessing the log
        my ( $handle, $cursor, $err, $msg, $flags) = (0, '', 0, '' ) ;
        $flags = Log::CJournalD::SD_JOURNAL_LOCAL_ONLY ;
        ok( 0 == ($err = Log::CJournalD::sd_journal_open( \$handle, $flags)) , 'sd_journal_open 1')  ;
        #diag ( "open handle ($err):" . Dumper($handle) ) ;
        ok( 1 == ($err = Log::CJournalD::sd_journal_next( $handle )) ,       'sd_journal_next 0')  ;
        ok( 0 == ( $err = Log::CJournalD::sd_journal_get_cursor( $handle, \$cursor ) ), 'sd_journal_get_cursor 1')  ;
        #diag ( "get cursor ($err):" . Dumper($cursor) ) ;
        ok( 0 == ($err = Log::CJournalD::sd_journal_get_data( $handle, 'MESSAGE', \$msg )) ,  'sd_journal_get_data 0')  ;
        #diag ( "get data ($err):" . Dumper($msg) ) ;

        ok( 0 == ($err = Log::CJournalD::sd_journal_seek_tail( $handle )) ,  'sd_journal_seek_tail 1')  ;
        ok( 1 == ($err = Log::CJournalD::sd_journal_previous( $handle )) ,   'sd_journal_previous 1')  ;
        ok( 0 == ($err = Log::CJournalD::sd_journal_seek_head( $handle )) ,  'sd_journal_head 1')  ;
        ok( 1 == ($err = Log::CJournalD::sd_journal_next( $handle )) ,       'sd_journal_next 1')  ;
        ok( 0 == ($err = Log::CJournalD::sd_journal_seek_head( $handle )) ,  'sd_journal_head 2')  ;
        ok( 1 == ($err = Log::CJournalD::sd_journal_previous( $handle )) ,   'sd_journal_previous 2')  ;

        ok( 0 == Log::CJournalD::sd_journal_test_cursor( $handle, $cursor ), 'sd_journal_test_cursor 1')  ;
        ok( 0 == ( $err = Log::CJournalD::sd_journal_get_cursor( $handle, \$cursor ) ), 'sd_journal_get_cursor 2')  ;
        ok( 1 == Log::CJournalD::sd_journal_test_cursor( $handle, $cursor ), 'sd_journal_test_cursor 2')  ;

        ok( 0 == ( $err = Log::CJournalD::sd_journal_getv( $handle, \$msg ) ), 'sd_journal_getv 1')  ;
        ok( exists $msg -> {MESSAGE}, 'sd_journal_getv: MESSAGE 1')  ;
        #diag ( "getv ($err):" . Dumper($msg) ) ;

        # LAST: Close handle
        ok( !Log::CJournalD::sd_journal_close( $handle ), 'sd_journal_close 1')  ; # returns void in C, always succeeds
        }
