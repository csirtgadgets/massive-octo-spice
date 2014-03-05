package CIF;

use 5.011;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use CIF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    normalize_timestamp debug init_logging
    is_ip is_asn is_email is_fqdn is_url is_url_broken is_protocol
    is_hash hash_create_random
    is_binary
    is_datetime normalize_timestamp
    protocol_to_int
    observable_type
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

#our $VERSION = '2.00000001';
#$VERSION = eval { $VERSION; };# see L<perlmodstyle>

use constant PROTOCOL_VERSION   => ;

use constant DEFAULT_PORT                   => 4961;
use constant DEFAULT_FRONTEND_PORT          => DEFAULT_PORT();
use constant DEFAULT_BACKEND_PORT           => (DEFAULT_PORT() + 1);
use constant DEFAULT_PUBLISHER_PORT         => (DEFAULT_PORT() + 2);
use constant DEFAULT_STATS_PUBLISHER_PORT   => (DEFAULT_PORT() + 3);

use constant DEFAULT_CONFIG => $ENV{'HOME'}.'/.cif';

use constant DEFAULT_QUERY_LIMIT    => 500;
use constant DEFAULT_GROUP          => 'everyone';

use vars qw($Logger);
use vars qw(
    $BasePath
    $LibPath
    $EtcPath
    $BinPath
    $SbinPath
    $VarPath
    $LocalPath
    $LocalEtcPath
    $LocalLibPath
    $RouterPath
    $RouterLibPath
    $SmrtPath
    $SmrtLibPath
);

# push these out to make this code simpler to read
# we still export the symbols though
use CIF::Plugin::Address qw(:all);
use CIF::Plugin::Hash qw(:all);
use CIF::Plugin::Binary qw(:all);
use CIF::Plugin::DateTime qw(:all);
use CIF::Plugin::Debug qw(:all);

use Log::Dispatch;
use File::Spec ();
use Cwd ();

__PACKAGE__->LoadGeneratedData();

# Preloaded methods go here.

sub observable_type {
    my $arg = shift || return;
    
    return 'url'    if(is_url($arg));
    return 'ipv4'   if(is_ipv4($arg));
    return 'ipv6'   if(is_ipv6($arg));
    return 'fqdn'   if(is_fqdn($arg));
    return 'email'  if(is_email($arg));
    return 'hash'   if(is_hash($arg));
    return 'binary' if(is_binary($arg));
    return 0;
}

no warnings;
sub init_logging {
    my $d = shift;
    return unless($d);
    
    $::debug = $d;
    require Log::Dispatch;
    unless($CIF::Logger){
        $CIF::Logger = Log::Dispatch->new();
        require Log::Dispatch::Screen;
        $CIF::Logger->add( 
            Log::Dispatch::Screen->new(
                name        => 'screen',
                min_level   => 'debug',
                stderr      => 1,
                newline     => 1
             )
        );
    }
}   
use warnings;

sub LoadGeneratedData {
    my $class = shift;
    my $pm_path = ( File::Spec->splitpath( $INC{'CIF.pm'} ) )[1] || 'lib';

    require "$pm_path/CIF/Generated.pm" || die "Couldn't load CIF::Generated: $@";
    $class->CanonicalizeGeneratedPaths();
}

sub CanonicalizeGeneratedPaths {
    my $class = shift;
    
    unless ( File::Spec->file_name_is_absolute($EtcPath) ) {
    
        # if BasePath exists and is absolute, we won't infer it from $INC{'CIF.pm'}.
        # otherwise CIF.pm will make the source dir(where we configure CIF) be the
        # BasePath instead of the one specified by --prefix
        unless ($BasePath &&  -d $BasePath && File::Spec->file_name_is_absolute($BasePath) ) {
                my $pm_path = ( File::Spec->splitpath( $INC{'CIF.pm'} ) )[1];
    
            # need rel2abs here is to make sure path is absolute, since $INC{'CIF.pm'}
            # is not always absolute
            $BasePath = File::Spec->rel2abs(
                File::Spec->catdir( $pm_path, File::Spec->updir ) 
            );
        }
    
        $BasePath = Cwd::realpath($BasePath);
    
        for my $path (qw/EtcPath BinPath SbinPath 
                            VarPath LocalPath LocalEtcPath
                            LocalLibPath
                            RouterPath RouterLibPath SmrtPath SmrtLibPath/) 
        {
            no strict 'refs';
            # just change relative ones
            $$path = File::Spec->catfile( $BasePath, $$path ) unless File::Spec->file_name_is_absolute($$path);
        }
    }

}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CIF - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CIF;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for CIF, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Wesley Young, E<lt>wes@macports.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Wesley Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
