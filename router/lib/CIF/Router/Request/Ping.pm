package CIF::Router::Request::Ping;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use Time::HiRes qw(tv_interval);

with 'CIF::Router::Request';
    
has 'Timestamp' => (
    is          => 'ro',
    isa         => 'Num',
    reader      => 'get_Timestamp',
    default     => sub { tv_interval() },
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

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;
 
    #$args->{'Timestamp'} = tv_interval() unless($args->{'Timestamp'});

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