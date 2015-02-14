package CIF::Router::Request::Ping;

use strict;
use warnings;

use Mouse;
use Time::HiRes qw(gettimeofday);
use CIF qw/$Logger/;
use Data::Dumper;

with 'CIF::Router::Request';
    
has 'Timestamp' => (
    is          => 'ro',
    default     => sub { gettimeofday() },
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} =~ /^ping(-write)?$/);
}

sub process {
    my $self = shift;
    my $args = shift;
    
    if($self->msg->{'rtype'} eq 'ping-write'){
        return 0 unless($self->user->{'write'});
    }
    
    return CIF::Message::Ping->new({
        Timestamp   => $self->Timestamp,
    });
}

__PACKAGE__->meta()->make_immutable();

1;