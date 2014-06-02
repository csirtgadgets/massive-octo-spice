package CIF::Meta::BgpPeers;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use Net::Abuse::Utils qw(get_as_description get_peer_info);
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
    
    my $peers = get_peer_info($o);

    foreach (@$peers){
        $_->{'asn_description'} = get_as_description($_->{'asn'});
    }

    $args->{'peers'}        = $peers if($peers);
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