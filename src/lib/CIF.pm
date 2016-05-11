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
    is_ip is_ip_private is_asn is_email is_fqdn is_url is_url_broken is_protocol
    is_hash hash_create_random is_hash_sha256 hash_create_static
    is_binary
    is_datetime normalize_timestamp
    protocol_to_int
    observable_type
    parse_config parse_rules
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
use Carp;

use YAML::Tiny;

use constant DEFAULT_CONFIG         => ($ENV{'HOME'}) ? $ENV{'HOME'}.'/.cif' : '';
use constant DEFAULT_GROUP          => 'everyone';

use constant {
    TLP_AMBER           => 'amber',
    TLP_DEFAULT         => 'amber',
    GROUP_DEFAULT       => 'everyone',
    LANG_DEFAULT        => 'EN',
    PROVIDER_DEFAULT    => 'unknown',
};

# Preloaded methods go here.

sub parse_config {
	my $config = shift;
    
	return unless(-e $config);
    my $config_data = YAML::Tiny->read($config) or croak("Cannot read $config, error: ", YAML::Tiny->errstr);
    return $config_data->[0];
}

sub parse_rule {
    my $rule = shift;
    my $feed = shift;
   
    $rule = parse_config($rule) unless(ref($rule) && ref($rule) eq 'HASH');
    
    croak('missing feed') unless($rule->{'feeds'}->{$feed});

    if($rule->{'feeds'}->{$feed}->{'parser'}){
        $rule->{'parser'} = $rule->{'feeds'}->{$feed}->{'parser'};
    }
    
    $rule->{'feed'} = $feed;
    
    if($rule->{'defaults'}){   
        $rule->{'defaults'} = { %{$rule->{'defaults'}}, %{$rule->{'feeds'}->{$feed}} };
    } else {
        $rule->{'defaults'} = {};
    }

    $rule = CIF::Rule->new($rule);

    return $rule;   
}
sub parse_rules {
    my $rule = shift;
    my $feed = shift;
    
    my @rules;
    if(-d $rule){
        opendir(F,$rule) || die('unable to open: '.$rule.'... '.$!);
        my $files = [ sort { $a cmp $b } grep (/.yml$/,readdir(F)) ];
        foreach my $f (@$files){
            my $t = parse_config("$rule/$f");
            foreach my $feed (keys %{$t->{'feeds'}}){
                my $x = parse_rule($t,$feed);
                $x->{'rule_path'} = "$rule/$f";
                push(@rules,$x); 
            }
        }
    } else {
        if($feed){
            my $x = parse_rule($rule,$feed);
            $x->{'rule_path'} = $rule;
            push(@rules, $x);
        } else {
            my $t = parse_config($rule);
            my @keys = sort { $a cmp $b } keys(%{$t->{'feeds'}});
            foreach my $feed (@keys){
                my $x = parse_rule($t,$feed);
                $x->{'rule_path'} = "$rule";
                push(@rules,$x);
            }
        }
    }
    return $rules[0] unless($#rules > 0); # more than one rule
    return \@rules;
}

sub observable_type {
    my $arg = shift || return;
    
    return 'url'    if(is_url($arg));
    return 'ipv4'   if(is_ipv4($arg));
    return 'ipv6'   if(is_ipv6($arg));
    return 'fqdn'   if(is_fqdn($arg));
    return 'email'  if(is_email($arg));
    
    if(my $htype = is_hash($arg)){
        return $htype;
    }
    
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
