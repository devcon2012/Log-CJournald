#
# Log::CJournalD - journald api exposed to perl
#
#   (c) Klaus Ramstöck klaus@ramstoeck.name 2020
#
# You can use and distribute this software under the same conditions as perl
#

use 5.018001;
use ExtUtils::MakeMaker;
use File::Find ;
use Cwd ;

our @modules ;

sub wanted
    {
    push @modules, $File::Find::name
        if ( /\.p[ml]$/ ) ;
    push @modules, $File::Find::name
        if ( /\.t$/ ) ;
    }

our @manifest ;
sub UpdateManifest
    {
    push @manifest, glob '*.md' ;
    push @manifest, glob '*.pl' ;
    push @manifest, glob '*.[ch]' ;
    push @manifest, glob 'example/*' ;
    push @manifest, 'LICENSE' ;
    push @manifest, 'Makefile.PL' ;
    push @manifest, 'Changes' ;
    push @manifest, 'perlcriticrc' ;
    push @manifest, '.gitignore' if ( -r '.gitignore' );


    find ( sub { push @manifest, $File::Find::name if ( /\.p[lm]$/ || /\.xs$/ ) ; },
            'lib', 'bin'
            );

    find ( sub { push @manifest, $File::Find::name if ( /\.t$/ ) ; },
            't'
            );

    open ( my $fh, ">", "MANIFEST.new")
        or die "cannot open MANIFEST.new: $!";
    print $fh join ("\n", sort { fc($a) cmp fc($b) } @manifest);
    print $fh "\n";
    close $fh ;
    if ( -r '/usr/bin/echo' )
        {
        system ("echo 'MANIFEST changes:' ; diff MANIFEST MANIFEST.new") ;
        system ("diff MANIFEST.new MANIFEST") ;
        system ("mv MANIFEST.new MANIFEST") ;
        }
    else
        {
        print "No /usr/bin/echo, not on unix?\n" ;
        print "Please check MANIFEST.new if you added any new files.\n" ;
        }
    }

sub CritiqueModules
    {
    find(\&wanted, 'lib', 'bin' );

    print STDERR "Run perlcritic on each module:\n";

    foreach my $m (@modules)
        {
        system("perlcritic --profile perlcriticrc $m")
            and print STDERR "ERROR in $m\n" ;
        }

    @modules = () ;
    find(\&wanted, 't' );

    print STDERR "Run perlcritic on each test:\n";

    foreach my $m (@modules)
        {
        system("perlcritic --profile perlcriticrc --theme tests $m")
            and print STDERR "ERROR in $m\n" ;
         }

    }

sub PrintInfo
    {
    print "Run some tests verbose:\n" ;
    print "make test TEST_VERBOSE=1 TEST_FILES='t/Log-CJournalD.t'\n" ;
    print "Run one test for debugging:\n" ;
    print "make testdb TEST_FILE=t/testInfoBites.t\n" ;
    }


WriteMakefile(
    NAME              => 'Log::CJournalD',
    VERSION_FROM      => 'lib/Log/CJournalD.pm',
    PREREQ_PM         => { 'Data::Dumper' => 1},
    ABSTRACT_FROM     => 'lib/Log/CJournalD.pm',
    AUTHOR            => 'Klaus Ramstöck <klaus@ramstoeck.name>',
    LICENSE           => 'perl',
    XSMULTI           => 1,
    LIBS              => ['-lsystemd'],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => '$(O_FILES)',
);


CritiqueModules() ;

UpdateManifest() ;

PrintInfo() ;
