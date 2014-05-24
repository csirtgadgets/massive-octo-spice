package CIF;

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
    $PidPath
    $LogPath
);

use CIF::Generated;

# push these out to make this code simpler to read
# we still export the symbols though
use CIF::Plugin::Address qw(:all);
use CIF::Plugin::Hash qw(:all);
use CIF::Plugin::Binary qw(:all);
use CIF::Plugin::DateTime qw(:all);

use CIF::Logger;

##TODO fix this
use constant DEFAULT_CONFIG         => ($ENV{'HOME'}) ? $ENV{'HOME'}.'/.cif' : '';
use constant DEFAULT_QUERY_LIMIT    => 500;
use constant DEFAULT_GROUP          => 'everyone';

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
	unless($args->{'category'}){
		my ($funct,$bin,$line) = caller();
		$args->{'category'} = $bin;
	}

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


1;