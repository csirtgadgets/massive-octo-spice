package CIF::Smrt::Broker;

use 5.011;
use warnings;
use strict;
use namespace::autoclean;

use Moose;
use MooseX::FollowPBP;

use CIF::Client;
use Data::Dumper;

has 'client' => (
    is          => 'ro',
    isa         => 'CIF::Client',
    required    => 1
);

has 'config'    => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'is_test'   => (
    is      => 'ro',
    isa     => 'Bool',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;
    
    $args->{'client'} = CIF::Client->new({%{$args->{'config'}}});
    
    return $self->$orig($args);
};  

sub process {
    my $self = shift;
    my $args = shift;
    
    return 1 if($self->get_is_test());
    
    my $rv = $self->get_client()->send($args);
    return $rv;
}

__PACKAGE__->meta->make_mutable();

1;