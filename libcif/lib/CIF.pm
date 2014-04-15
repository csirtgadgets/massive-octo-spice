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
    is_hash hash_create_random is_hash_sha256 hash_create_static
    is_binary
    is_datetime normalize_timestamp
    protocol_to_int
    observable_type
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    $Logger 
);

# push these out to make this code simpler to read
# we still export the symbols though
use CIF::Plugin::Address qw(:all);
use CIF::Plugin::Hash qw(:all);
use CIF::Plugin::Binary qw(:all);
use CIF::Plugin::DateTime qw(:all);

use CIF::Logger;
use File::Spec ();
use Cwd ();

__PACKAGE__->LoadGeneratedData();

use constant DEFAULT_CONFIG         => $ENV{'HOME'}.'/.cif';
use constant DEFAULT_QUERY_LIMIT    => 500;
use constant DEFAULT_GROUP          => 'everyone';

use vars qw(
    $Logger
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
    $SmrtRulesPath
    $SmrtRulesDefault
    $SmrtRulesContrib
    $SmrtRulesLocal
    $CIF_USER
    $CIF_GROUP
);

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

sub init_logging {
    my $args        = shift;
    my $mail_args   = shift;

    $args = { level => $args } unless(ref($args) && ref($args) eq 'HASH');

    $Logger = CIF::Logger->new($args);

    if($args->{'filename'}){
        my $appender = Log::Log4perl::Appender->new(
            'Log::Log4perl::Appender::File', 
            mode                => 'append',
            %$args
        );
        $appender->layout(
            Log::Log4perl::Layout::PatternLayout->new(
                $Logger->get_layout()
            )
        );
        $Logger->get_logger()->add_appender($appender);
    }
    
    if($mail_args){
        my $appender = Log::Log4perl::Appender->new(
        "Log::Dispatch::Email::MIMELite",
            %$mail_args,
            buffered    => 0,
            layout              => Log::Log4perl::Layout::PatternLayout->new(),
            ConversionPattern   => $Logger->get_layout(),
        );
        $Logger->get_logger()->add_appender($appender);
    }
    $Logger = $Logger->get_logger();
}

sub LoadGeneratedData {
    my $class = shift;
    my $pm_path = ( File::Spec->splitpath( $INC{'CIF.pm'} ) )[1] || 'lib';

    require $pm_path."/CIF/Generated.pm" || die "Couldn't load CIF::Generated: $@";
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