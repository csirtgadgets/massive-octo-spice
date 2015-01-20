package CIF::Meta::GeoIP;

use strict;
use warnings;

use Mouse;
use GeoIP2::Database::Reader;
use CIF qw/is_ip is_ip_private $Logger/;
use Try::Tiny;
use Carp;

with 'CIF::Meta';

## http://dev.maxmind.com/geoip/geoip2/geolite2/
use constant FILE_LOC       => $CIF::VarPath."/cache/GeoLite2-City.mmdb";

has 'handle' => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_handle {
    my $self = shift;
    return GeoIP2::Database::Reader->new(file => FILE_LOC);
}

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless(-e FILE_LOC());

    return unless($args->{'observable'});
    return unless(is_ip($args->{'observable'}));
    return unless(!is_ip_private($args->{'observable'}));

    return 1;
}


## TODO - is_network needs to return the .0 instead of the .0/24 o/w Data::Validate::IP / Maxmind
## get confused

sub process {
    my $self = shift;
    my $args = shift;

    ## TOOD -- maxmind has a hard time with Prefixes (/24 /16, etc...)
    ## needs some upstream help
    my $ip = _strip($args->{'observable'});

    $Logger->debug('checking: '.$args->{'observable'});
    my ($err,$ret);
    try {
        $ret = $self->handle->omni(ip => $ip);
    } catch {
        $err = shift;
    };
    if($err){
        for($err){
            if(/^No record/){
                return;
            }
            if(/is not a public IP/){
                return;
            }
        }
        croak($err);
    }
    if($ret){
        $args->{'cc'}           = $ret->country()->iso_code()                   if($ret->country()->iso_code() && !$args->{'cc'});
        $args->{'citycode'}     = $ret->city()->names->{'en'}                   if($ret->city()->names->{'en'}); ## TODO -- configurable
        $args->{'latitude'}     = $ret->location()->latitude()                  if($ret->location()->latitude());
        $args->{'longitude'}    = $ret->location()->longitude()                 if($ret->location()->longitude());
        $args->{'subdivision'}  = $ret->most_specific_subdivision()->iso_code() if($ret->most_specific_subdivision()->iso_code());
        $args->{'timezone'}     = $ret->location()->time_zone()                 if($ret->location()->time_zone());
        $args->{'metrocode'}    = $ret->location()->metro_code()                if($ret->location()->metro_code());
    }
}

sub _strip {
    my $addr = shift;
    
    my @bits = split(/\./,$addr);
    
    $bits[$#bits] = 0;
    $addr = join('.',@bits);
    return $addr;   
}

__PACKAGE__->meta->make_immutable();

1;