package CIF::Worker;

use strict;
use warnings;
use feature 'say';

use Mouse;
use CIF qw/init_logging $Logger/;
use CIF::Client;
use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_SUB ZMQ_SNDTIMEO ZMQ_RCVTIMEO ZMQ_LINGER ZMQ_PUSH ZMQ_PULL);
use JSON::XS;
use Try::Tiny;
use Data::Dumper;
use CIF::ObservableFactory;
use CIF::WorkerFactory;
use CIF::MetaFactory;

use constant {
    PUBLISHER       => 'tcp://localhost:'.CIF::DEFAULT_PUBLISHER_PORT,
    ROUTER          => 'tcp://localhost:'.CIF::DEFAULT_FRONTEND_PORT,
    CONFIDENCE_MIN  => 25,
    SND_TIMEOUT     => 320000,
    RCV_TIMEOUT     => 320000,
    DATA_PIPE       => 'ipc:///tmp/cif_workers_data',
};

has 'token' => (
    is  => 'ro',
);

has 'router'   => (
    is      => 'ro',
    default => sub { ROUTER },
);

has 'publisher' => (
    is  => 'ro',
    default => sub { PUBLISHER },
);

has 'dummy' => ( is => 'ro' );

has [qw(context router_socket subscriber_socket workers_socket data_socket)] => (
    is          => 'ro',
    lazy_build  => 1,
);

has '_worker_plugins' => (
    is  => 'ro',
    default => sub { [ CIF::WorkerFactory::_worker_plugins() ] },
);

has 'metadata_plugins'  => (
    is      => 'ro',
    default => sub { [ CIF::MetaFactory::_metadata_plugins() ] },
);

sub _build_context {
    return ZMQ::FFI->new();
}

sub _build_router_socket {
    my $self = shift;
    
    my $socket = $self->context->socket(ZMQ_REQ);
    $socket->set(ZMQ_SNDTIMEO,'int',SND_TIMEOUT());
    $socket->set(ZMQ_RCVTIMEO,'int',RCV_TIMEOUT());
    $socket->connect($self->router());
    
    return $socket;
}

sub _build_subscriber_socket {
    my $self = shift;
    
    my $socket = $self->context->socket(ZMQ_SUB);
    $socket->subscribe('');
    $socket->connect($self->publisher());
    
    return $socket;
}

sub _build_workers_socket {
    my $self = shift;
    
    my $socket = $self->context->socket(ZMQ_PUSH);
    $socket->bind(DATA_PIPE);
    
    return $socket;
}

sub _build_data_socket {
    my $self = shift;
    
    my $socket = $self->context->socket(ZMQ_PULL);
    $socket->connect(DATA_PIPE);
    
    return $socket;
}

sub BUILD {
    my $self = shift;
    
    init_logging({ level => 'ERROR'}) unless($Logger);
}

sub encode {
    my $self = shift;
    my $data = shift;
    
    return JSON::XS->new->pretty->convert_blessed(1)->encode($data);
}

sub decode {
    my $self = shift;
    my $data = shift;
    
    return JSON::XS->new->decode($data);
}

sub start_subscriber {
    my $self    = shift;
    my $cb      = shift;
    
    $Logger->info('starting...');
	
	return AnyEvent->io(
	   fh      => $self->subscriber_socket->get_fd(),
	   poll    => 'r',
	   cb      => $cb,
    );
}

sub start_worker {
    my $self = shift;
    my $cb = shift || sub { $self->process };
    
    return AnyEvent->io(
	   fh      => $self->data_socket->get_fd(),
	   poll    => 'r',
	   cb      => $cb,
    );
}

sub process {
    my $self    = shift;
    my $data    = shift;

    my $new;
    $data = $self->decode($data);
    foreach my $p (@{$self->_worker_plugins}){
        next unless($data->{'confidence'} && $data->{'confidence'} >= CONFIDENCE_MIN);
        $data = CIF::ObservableFactory->new_plugin($data);
        next unless($p->understands($data));
        $Logger->debug('processing: '.$p);
        if(my $tmp = $p->new->process($data)){
            foreach my $t (@$tmp){
                $self->_process_metadata($t);
                $t = CIF::ObservableFactory->new_plugin($t);
            }
            push(@$new,@$tmp) if($#{$tmp} > -1);
        }
    }
    if($new){
        $Logger->debug('sending to router');
        my $x = $self->send($new) unless $self->dummy;
        return 1;
    } else {
        $Logger->debug('no new msgs to send...');
        return 1;
    }
}

sub _process_metadata {
    my $self = shift;
    my $data = shift;
    
    foreach my $p (@{$self->metadata_plugins}){
        next unless($p->understands($data));
        $p->new()->process($data);
    }
}

sub send {
    my $self = shift;
    my $msg  = shift;
    
    $msg = CIF::Message->new({
        rtype       => 'submission',
        mtype       => 'request',
        Token       => $self->token,
        Observables => $msg,
    });
    
    $Logger->debug('encoding...');
    
    if($Logger->is_debug()){
        $msg = JSON::XS->new->pretty->convert_blessed(1)->encode($msg);
    } else {
        $msg = JSON::XS->new->convert_blessed(1)->encode($msg);
    }
    
    $Logger->debug('sending upstream...');
    
    my ($ret,$err);
    $ret = $self->router_socket->send($msg);
    
    try {
        $msg = $self->router_socket->recv;
    } catch {
        $err = shift;
    };
    
    if($err){
        for($err){
            if(/Resource temporarily unavailable/){
                $Logger->debug('cif-router timeout...');
                # o/w queued msgs will hang the context thread
                $self->router_socket->set(ZMQ_LINGER,'int',0);
                return 0;
            }
            $Logger->fatal($err);
            return 0;
        }
    }
    
    $Logger->debug('decoding...');
    $msg = JSON::XS->new->decode($msg);
    
    $msg = ${$msg}[0] if(ref($msg) && ref($msg) eq 'ARRAY');
    
    return $msg;
}

__PACKAGE__->meta->make_immutable();  

1;
