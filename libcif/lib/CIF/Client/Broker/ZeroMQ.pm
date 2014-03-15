package CIF::Client::Broker::ZeroMQ;

use 5.011;
use warnings;
use strict;

use Mouse;
use ZMQx::Class;
use ZMQ::LibZMQ3;
use Carp;
use Carp::Assert;

with 'CIF::Client::Broker';

use constant RE_REMOTE  => qr/^((zeromq|zmq)(\+))?(tcp|inproc|ipc|proc)\:\/{2}([[\S]+|\*])(\:(\d+))?$/;

has 'socket' => (
    is      => 'rw',
    isa     => 'ZMQx::Class::Socket',
    reader  => 'get_socket',
    writer  => 'set_socket',
);

sub understands {
    my $self = shift;
    my $args = shift;

    return 0 unless($args->{'remote'});
    return 1 if($args->{'remote'} =~ RE_REMOTE());

    return 0;
}

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my %args    = @_;
    
    $args{'remote'} =~ s/^(zeromq|zmq)\+?//g;

    return $self->$orig(%args);
};

##TODO
# this could actually be a DEALER socket
# to handle async, but would need to re-work the 'worker' queues a bit on the backend
# re-write this outside of ZMQx::Class, or re-write ZMQx::Class to have better threading support
sub BUILD {
    my $self = shift;
    $self->set_socket(
        ZMQx::Class->socket(
            'REQ',
            connect => $self->get_remote(),
        )
    );
}

# this should already be a string by the time it hits us
sub send {
    my $self = shift;
    my $msg = shift;

    my $ret = $self->get_socket->send($msg);
    return 0 unless($ret);
    
    $ret = $self->get_socket->receive('blocking');
    
    assert($ret);
    return @{$ret}[0];
}

sub shutdown {
    my $self = shift;

    $self->{'socket'} = undef;

    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->shutdown();
}

__PACKAGE__->meta->make_immutable(inline_destructor => 0);

1;
