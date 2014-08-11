package CIF::Meta::BGP;

use strict;
use warnings;

use Mouse;
use Net::Abuse::Utils qw(get_as_description get_asn_info get_peer_info);
use CIF qw/is_ip $Logger/;
use Try::Tiny;

with 'CIF::Meta';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'observable'});
    return unless(is_ip($args->{'observable'}));
    return 1;
}

sub process {
    my $self = shift;
    my $args = shift;

    my $o = _strip($args->{'observable'});

    $Logger->debug('checking: '.$o);
    
    my ($asn,$prefix,$cc,$rir,$date) = get_asn_info($o);
    my $asn_desc;
    $asn_desc = get_as_description($asn) if($asn);
    
    $args->{'asn'}          = $asn if($asn);
    $args->{'asn_desc'}     = $asn_desc if($asn_desc);
    $args->{'prefix'}       = $prefix if($prefix);
    $args->{'cc'}  = $cc if($cc && $cc ne '');
    $args->{'rir'}          = $rir if($rir);
}

# aggregate our cache , we could miss a more specific route, 
# but unlikely given the way the tubes work
sub _strip {
    my $addr = shift;

    my @bits = split(/\./,$addr);
    $bits[$#bits] = 0;
    $addr = join('.',@bits);
    
    return $addr;
    
}

__PACKAGE__->meta->make_immutable();

1;