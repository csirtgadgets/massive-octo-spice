package CIF::Message::Ping;

use strict;
use warnings;

use Mouse;
use Time::HiRes qw(gettimeofday);
    
has 'Timestamp' => (
    is          => 'ro',
    isa         => 'Num',
    reader      => 'get_Timestamp',
    lazy        => 1,
    default     => sub { gettimeofday() },
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'ping');
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    return $self->$orig($args);
};

sub TO_JSON {
    my $self = shift;
    
    return {
        'Timestamp'    => $self->get_Timestamp(),
    };
}

__PACKAGE__->meta()->make_immutable();

1;