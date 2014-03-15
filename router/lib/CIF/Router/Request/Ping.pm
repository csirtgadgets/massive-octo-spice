package CIF::Router::Request::Ping;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use Time::HiRes qw(gettimeofday);

with 'CIF::Router::Request';
    
has 'Timestamp' => (
    is          => 'ro',
    isa         => 'Num',
    reader      => 'get_Timestamp',
    default     => sub { gettimeofday() },
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'@rtype'});
    return 1 if($args->{'@rtype'} eq 'ping');
}

sub process {
    my $self = shift;
    my $args = shift;
    
    return CIF::Message::Ping->new({
        Timestamp   => $self->get_Timestamp(),
    });
}

sub TO_JSON {
    my $self = shift;
    
    return {
        'Timestamp'    => $self->get_Timestamp(),
    };
}

__PACKAGE__->meta()->make_immutable();

1;