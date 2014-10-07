package CIF::Message::Ping;

use strict;
use warnings;

use Mouse;
use Time::HiRes qw(gettimeofday);
    
has 'Timestamp' => (
    default     => sub { gettimeofday() },
    lazy        => 1,
    is  => 'ro',
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'ping');
}

sub TO_JSON {
    my $self = shift;
    
    return {
        'Timestamp'    => $self->Timestamp,
    };
}

__PACKAGE__->meta()->make_immutable();

1;