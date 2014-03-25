package CIF::Client::Broker::ZeroMQ;

use 5.011;
use warnings;
use strict;

use Mouse;
use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_SUB);
use Carp;
use Carp::Assert;
use CIF qw(debug);

with 'CIF::Client::Broker';

use constant RE_REMOTE  => qr/^((zeromq|zmq)(\+))?(tcp|inproc|ipc|proc)\:\/{2}([[\S]+|\*])(\:(\d+))?$/;

has 'context' => (
    is      => 'rw',
    reader  => 'get_context',
    writer  => 'set_context',
    default => sub { ZMQ::FFI->new() },
);

has 'socket' => (
    is          => 'rw',
    reader      => 'get_socket',
    writer      => 'set_socket',
    builder     => '_build_socket',
    required    => 1,
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

sub _build_socket {
    my $self = shift;
    my $args = shift;

    my $socket = $self->get_context()->socket(
        ($self->get_subscriber()) ? ZMQ_SUB : ZMQ_REQ
    );
    $socket->subscribe('') if($self->get_subscriber());
    $socket->connect($self->get_remote());
    return $socket;
    
}

sub receive {
    return shift->get_socket()->recv();
}

sub get_fd {
    return shift->get_socket->get_fd();
}

# this should already be a string by the time it hits us
sub send {
    my $self = shift;
    my $msg = shift;

    my $ret = $self->get_socket->send($msg);
    
    $ret = $self->get_socket->recv();
    return $ret;
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
