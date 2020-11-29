package Log::CJournalD;

use 5.026001;
use strict;
use warnings;

use Data::Dumper ;
use Log::CJournalD::handle ;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Log::CJournalD ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

# https://www.freedesktop.org/software/systemd/man/sd_journal_print.html#
# https://www.freedesktop.org/software/systemd/man/sd_journal_open.html#
# https://www.freedesktop.org/software/systemd/man/sd_journal_get_cursor.html#

our %EXPORT_TAGS = ( 'all' => [ qw(
sd_journal_print
sd_journal_send
sd_journal_sendv
sd_journal_perror
sd_journal_open
sd_journal_open_directory
sd_journal_close
sd_journal_getv
sd_journal_get_data
sd_journal_enumerate_data
sd_journal_restart_data
sd_journal_get_cursor
sd_journal_seek_head
sd_journal_seek_tail
sd_journal_next
sd_journal_previous
sd_journal_seek_cursor
SD_JOURNAL_LOCAL_ONLY
SD_JOURNAL_RUNTIME_ONLY
SD_JOURNAL_SYSTEM
SD_JOURNAL_CURRENT_USER
SD_JOURNAL_OS_ROOT
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.1';

use Carp ;

require XSLoader;
XSLoader::load() ;

# Preloaded methods go here.

# most liekly there is a better way ...
sub SD_JOURNAL_OS_ROOT
    {
    return _SD_JOURNAL_OS_ROOT() ;
    }
sub SD_JOURNAL_CURRENT_USER
    {
    return _SD_JOURNAL_CURRENT_USER() ;
    }
sub SD_JOURNAL_SYSTEM
    {
    return _SD_JOURNAL_SYSTEM() ;
    }
sub SD_JOURNAL_RUNTIME_ONLY
    {
    return _SD_JOURNAL_RUNTIME_ONLY() ;
    }
sub SD_JOURNAL_LOCAL_ONLY
    {
    return _SD_JOURNAL_LOCAL_ONLY() ;
    }

## no critic (RequireArgUnpacking) ;
sub sd_journal_print
  {
  my ( $prio, $fmt ) = @_ ;

  shift ; shift ;

  my $data ;
  if ( scalar @_ )
    {
    $data = sprintf ( $fmt, @_ ) ;
    }
  else
    {
    $data = $fmt ;
    }
  return _sd_journal_print( $prio, $data ) ;
  }
## use critic

sub sd_journal_send
  {
  my %data = @_ ;
  my @formatted ;
  foreach my $k ( keys %data )
    {
    my $v = $data{$k} ;
    $k = uc $k ;
    push @formatted, "$k=$v" ;
    }
  return _sd_journal_sendv( \@formatted ) ;
  }

sub sd_journal_sendv
  {
  my $data = shift ;
  my @formatted ;
  foreach my $k ( keys %$data )
    {
    my $v = $data->{$k} ;
    $k = uc $k ;
    push @formatted, "$k=$v" ;
    }
  return _sd_journal_sendv( \@formatted ) ;
  }

sub sd_journal_perror
  {
  my $msg = shift ;
  return _sd_journal_perror( $msg ) ;
  }

# int sd_journal_open(sd_journal **ret, int flags);
sub sd_journal_open
  {
  my ($handle, $flags) = @_ ;
  $flags //= 0 ;

  croak ("handle entered not a scalar ref1")
    if ( 'SCALAR' ne ref $handle ) ;

  my $ret = _sd_journal_open( $flags ) ;
  $$handle = $ret -> [0] ;
  return $ret -> [1] ;
  }

# int sd_journal_open_directory(sd_journal **ret, const char * path, int flags);
sub sd_journal_open_directory
  {
  my ($handle, $path, $flags) = @_ ;
  $path //= '/' ;
  $flags //= 0 ;

  croak ("handle entered not a scalar ref1")
    if ( 'SCALAR' ne ref $handle ) ;

  my $ret = _sd_journal_open_directory( $path, $flags ) ;
  $$handle = $ret -> [0] ;
  return $ret -> [1] ;
  }

# void sd_journal_close(sd_journal *j);
sub sd_journal_close
  {
  my ($handle) = @_ ;

  _sd_journal_close( $handle ) ;
  return ;
  }


# int sd_journal_get_data(sd_journal *j, char *field, void **data, size_t &length);
sub sd_journal_get_data
  {
  my ($handle, $field, $data) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  croak ("data not a scalar ref")
    if ( 'SCALAR' ne ref $data ) ;

  my $ret = _sd_journal_get_data( $handle, $field ) ;
  $$data = $ret -> [0] ;
  return $ret -> [1] ;

  }

#
sub sd_journal_getv
  {
  my ($handle, $data) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  croak ("data not a ref")
    if ( ! ref $data ) ;

  sd_journal_restart_data ( $handle ) ;
  my ($entry, %data, $errc ) ;
  while ( ( $errc = sd_journal_enumerate_data( $handle, \$entry) ) > 0 )
    {
    my ($key, $value) = $entry =~ /^([^\=]+)\=(.*)$/ ;
    $data{$key} = $value ;
    }
  $$data = \%data ;
  return $errc;
  }

# int sd_journal_enumerate_data(sd_journal *j, char *field, void **data, size_t &length);
sub sd_journal_enumerate_data
  {
  my ($handle, $data) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  croak ("data not a scalar ref")
    if ( 'SCALAR' ne ref $data ) ;

  my $ret = _sd_journal_enumerate_data( $handle ) ;

  $$data = $ret -> [0] ;
  return $ret -> [1] ;

  }

# void sd_journal_restart_data(sd_journal *j);
sub sd_journal_restart_data
  {
  my ($handle) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  sd_journal_restart_data( $handle ) ;
  return ;
  }

# int sd_journal_get_cursor(sd_journal *j, char **cursor);
sub sd_journal_get_cursor
  {
  my ($handle, $cursor) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  croak ("cursor not a scalar ref")
    if ( 'SCALAR' ne ref $cursor ) ;

  my $ret = _sd_journal_get_cursor( $handle ) ;
  $$cursor = $ret -> [0] ;
  return $ret -> [1] ;

  }

# int sd_journal_test_cursor(sd_journal *j, const char *cursor);
sub sd_journal_test_cursor
  {
  my ($handle, $cursor) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  return _sd_journal_test_cursor( $handle, $cursor ) ;
  }

# int sd_journal_next(sd_journal *j);
sub sd_journal_next
  {
  my ($handle) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  return _sd_journal_next( $handle ) ;
  }

# int sd_journal_previous(sd_journal *j);
sub sd_journal_previous
  {
  my ($handle) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  return _sd_journal_previous( $handle ) ;
  }

# int sd_journal_seek_head(sd_journal *j);
sub sd_journal_seek_head
  {
  my ($handle) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  return _sd_journal_seek_head( $handle ) ;
  }

# int sd_journal_seek_tail(sd_journal *j);
sub sd_journal_seek_tail
  {
  my ($handle) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;

  return _sd_journal_seek_tail( $handle ) ;
  }

sub sd_journal_seek_cursor
  {
  my ($handle, $cursor) = @_ ;

  croak ("handle not a Log::CJournalD::handle")
    if ( ! $handle -> isa ( 'Log::CJournalD::handle' ) ) ;
  croak ("cursor not a cursor")
    if ( ! $handle -> isa ( 'Log::CJournalD::cursor' ) ) ;

  return _sd_journal_seek_cursor( $handle, $cursor ) ;
  }

1;

__END__

=head1 NAME

Log::CJournalD - Perl extension for journald access

=head1 SYNOPSIS

  use Log::CJournalD ':all' ;

  # logging examples. Please note C-API returns 0 on success
  sd_journal_print(INFO, "%s: copied %i of %i files", $prg, $i, $max )
      and croak("cannot log") ;

  sd_journal_send( SPECIAL_TAG => $special, MESSAGE => $message ) ;
  sd_journal_send( %context, $message ) ;
  sd_journal_sendv( \%structured_entry ) ;
  sd_journal_sendv( \%context, $message ) ;

  # examine journal (might require special priviledges)
  my $flags = SD_JOURNAL_LOCAL_ONLY ;
  my ($handle, $cursor, $data ) ;

  sd_journal_open( \$handle, SD_JOURNAL_LOCAL_ONLY)
    and carp ( "cannot open journal" ) ;

  sd_journal_next ( $handle )
    or carp ( "cannot seek journal handle" ) ;

  sd_journal_enumerate_data( $handle, \$data )
    or carp ( "cannot enumerate" ) ;

  while ( 0 == sd_journal_get_data ( $handle, 'MESSAGE', \$data ) )
    {
    print "$data:" . Dumper ( $data ) ;
    $count++ ;
    sd_journal_next ( $handle )
        or last ;
    }

  sd_journal_get_cursor ( $handle, \$cursor )
    and carp ("cannot get a cursor") ;

  # this function has no corresponding C function with the same name.
  # It will set $data to a hash ref containing the current entry
  sd_journal_getv ( $handle, \$data )
    and carp ( "cannot getv" ) ;

=head1 DESCRIPTION

  Log::CJournalD tries to provide the full C journald API with all its rough edges.
  From a perl perspective, you need to be very careful wrt the codes returned.
  Consult the man pages of the corresponding c functions if in doubt.

=head2 EXPORT

None by default.

=head1 SEE ALSO

* www.freedesktop.org
* man

=head1 AUTHOR

Klaus Ramstöck, E<lt>klra67@freenet.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
