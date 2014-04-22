package CIF::Client::Broker::ZeroMQ;

use warnings;
use strict;

use Mouse;
use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_SUB ZMQ_SNDTIMEO ZMQ_RCVTIMEO ZMQ_LINGER);
use Carp;
use Carp::Assert;
use CIF qw($Logger);
use Try::Tiny;

with 'CIF::Client::Broker';

use constant RE_REMOTE      => qr/^((zeromq|zmq)(\+))?(tcp|inproc|ipc|proc)\:\/{2}([[\S]+|\*])(\:(\d+))?$/;
use constant SND_TIMEOUT    => 5000;
use constant RCV_TIMEOUT    => 30000;
use constant PING_TIMEOUT   => 5000; ##TODO seperate ping timeouts from SND/RCV timeouts

has 'context' => (
    is      => 'rw',
    reader  => 'get_context',
    writer  => 'set_context',
    builder => '_build_context',
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

sub _build_context {
    my $self = shift;
    
    return ZMQ::FFI->new();
}

sub _build_socket {
    my $self = shift;
    my $args = shift;

    my $socket = $self->get_context()->socket(
        ($self->get_subscriber()) ? ZMQ_SUB : ZMQ_REQ
    );
    $socket->set(ZMQ_SNDTIMEO,'int',SND_TIMEOUT());
    $socket->set(ZMQ_RCVTIMEO,'int',RCV_TIMEOUT());
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
    my $self    = shift;
    my $msg     = shift;

    my ($ret,$err);
    $ret = $self->get_socket->send($msg);
    
    try {
        $ret = $self->get_socket->recv();
    } catch {
        $err = shift;
    };
    
    if($err){
        
        for($err){
            if(/Resource temporarily unavailable/){
                $Logger->debug('cif-router timeout...');
                # o/w queued msgs will hang the context thread
                $self->get_socket()->set(ZMQ_LINGER,'int',0);
                return 0;
            }
            $Logger->error($err);
        }
    }
    
    return $ret;
}

sub shutdown {}

__PACKAGE__->meta->make_immutable();

1;
