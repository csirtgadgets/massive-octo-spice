package CIF::Meta::BGP;

use strict;
use warnings;
use namespace::autoclean;

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

    # aggregate our cache , we could miss a more specific route, 
    # but unlikely given the way the tubes work
    my $o = $args->{'observable'};
    my @bits = split(/\./,$o);
    
    $bits[$#bits] = 0;
    $o = join('.',@bits);

    $Logger->debug('[BGP] checking: '.$o);
    
    my ($asn,$prefix,$cc,$rir,$date) = get_asn_info($o);
    my $asn_desc;
    $asn_desc = get_as_description($asn) if($asn);
    
    my $peers = get_peer_info($o);
    
    foreach (@$peers){
        $_->{'asn_description'} = get_as_description($_->{'asn'});
    }
    
    $args->{'asn'}          = $asn if($asn);
    $args->{'asn_desc'}     = $asn_desc if($asn_desc);
    $args->{'prefix'}       = $prefix if($prefix);
    $args->{'countrycode'}  = $cc if($cc && $cc ne '');
    $args->{'rir'}          = $rir if($rir);
    $args->{'peers'}        = $peers if($peers);
}

__PACKAGE__->meta->make_immutable();

1;