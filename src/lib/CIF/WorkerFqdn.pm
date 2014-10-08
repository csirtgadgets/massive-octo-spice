package CIF::WorkerFqdn;

use strict;
use warnings;

use Mouse::Role;
use Net::DNS::Resolver;

use CIF qw/is_fqdn/;

with 'CIF::WorkerRole';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless(is_fqdn($args->{'observable'}));
    return 1;
}

sub resolve {
    my $self = shift;
    my $addr = shift;
    my $type = shift || 'A';
    
    my $r = Net::DNS::Resolver->new(recursive => 0);
    $r->udp_timeout(2);
    $r->tcp_timeout(2);
    
    my $pkt = $r->send($addr,$type);
    return unless($pkt);
    my @rdata = $pkt->answer();
    return(\@rdata);
}

1;
