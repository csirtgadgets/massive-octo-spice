package CIF::Observable::Ipv4;

use strict;
use warnings;

use Mouse;
use Data::Dumper;
use CIF qw/is_ip $Logger/;

with 'CIF::ObservableAddressIP';

has '+otype' => (
    is      => 'ro',
    default => 'ipv4',
);

sub process {}

sub _normalize {
    my $addr = shift;

    my @bits = split(/\./,$addr);
    foreach(@bits){
        if(/^0+\/(\d+)$/){
            $_ = '0/'.$1;
        } else {
            next if(/^0$/);
            next unless(/^0{1,2}/);
            $_ =~ s/^0{1,2}//;
        }
    }
    return join('.',@bits);
}

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'observable'});
    return unless(is_ip($args->{'observable'}) eq 'ipv4');
    $args->{'observable'} = _normalize($args->{'observable'});
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;