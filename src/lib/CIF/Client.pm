package CIF::Client;

use strict;
use warnings;

use Data::Dumper;
use Mouse;
use CIF qw/init_logging $Logger normalize_timestamp/;
use CIF::Message;
use CIF::ObservableFactory;
use JSON::XS;

use Time::HiRes qw(tv_interval gettimeofday);
use Data::Dumper;
use Carp::Assert;
use Try::Tiny;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_SUB ZMQ_SNDTIMEO ZMQ_RCVTIMEO ZMQ_LINGER);

use constant SND_TIMEOUT    => 120000;
use constant RCV_TIMEOUT    => 120000;
use constant PING_TIMEOUT   => 5000; ##TODO seperate ping timeouts from SND/RCV timeouts
use constant REMOTE_DEFAULT => 'tcp://localhost:'.CIF::DEFAULT_PORT();

has [qw(remote subscriber results Token)] => (
    is  => 'ro',
);

has [qw(context socket)] => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_context {
    return ZMQ::FFI->new();
}

sub _build_socket {
    my $self = shift;
    
    my $socket = $self->context->socket(
        ($self->subscriber()) ? ZMQ_SUB : ZMQ_REQ
    );
    $socket->set(ZMQ_SNDTIMEO,'int',SND_TIMEOUT());
    $socket->set(ZMQ_RCVTIMEO,'int',RCV_TIMEOUT());
    $socket->subscribe('') if($self->subscriber());
    $socket->connect($self->remote());
    
    return $socket;
}

sub BUILD {
    my $self = shift;
    init_logging({ level => 'WARN' }) unless($Logger);
}

sub receive {
    my $self = shift;
    my $msg = $self->socket->receive();
    $msg = JSON::XS->new->decode($msg);
    map { $_ = CIF::ObservableFactory->new_plugin($_) } (@{$msg});
    return $msg;
}

sub subscribe {
	my $self = shift;
	my $cb = shift;
	
	return AnyEvent->io(
	   fh      => $self->socket->get_fd(),
	   poll    => 'r',
	   cb      => $cb,
    );
}

sub ping {
    my $self = shift;
    my $args = shift;
    
    $Logger->info('generating ping request...');
    my $msg = CIF::Message->new({
        rtype   => 'ping',
        mtype   => 'request',
        Token   => $self->Token(),
    });
    $Logger->info('sending ping...');
    my $ret = $self->send($msg);
    if($ret){
        my $ts = $msg->{'Data'}->{'Timestamp'};
        $Logger->info('ping returned');
        return tv_interval([split(/\./,$ts)]);
    } else {
        $Logger->warn('timeout...');
    }
    return 0;
}

sub search {
    my $self = shift;
    my $args = shift;
    
    my $filters = $args->{'Filters'};
    if($filters->{'starttime'}){
    	unless($filters->{'starttime'} =~ /^\d+$/){
    		$filters->{'starttime'} =  DateTime::Format::DateParse->parse_datetime($filters->{'starttime'});
    		$filters->{'starttime'} = $filters->{'starttime'}->epoch.'000'; #millis
    	}
    }
    
    if($filters->{'tags'} && $filters->{'tags'} =~ /,/){
    	$filters->{'tags'} = [split(/,/,$filters->{'tags'})];
    }
    
    if($filters->{'groups'} && $filters->{'groups'} =~ /,/){
    	$filters->{'groups'} = [split(/,/,$filters->{'groups'})];
    }
    
    my $msg;
    if($args->{'Id'}){
    	$msg = CIF::Message->new({
    		rtype      => 'search',
	        mtype      => 'request',
	        Token      => $args->{'Token'} || $self->Token(),
	        Id         => $args->{'Id'},
	        feed       => $args->{'feed'},
    	});
    } else {
    	$msg = CIF::Message->new({
	        rtype      => 'search',
	        mtype      => 'request',
	        Token      => $args->{'Token'} || $self->Token(),
	        Query      => $args->{'Query'},
	        Filters    => $filters,
	        feed       => $args->{'feed'},
	    });
    }
    $msg = $self->send($msg);
    
    #$Logger->debug(Dumper($msg));
    
    my $stype = $msg->{'stype'} || $msg->{'stype'};
    return $msg->{'Data'} if($stype eq 'failure');
    
    unless($args->{'nodecode'}){
        map { $_ = CIF::ObservableFactory->new_plugin($_) } (@{$msg->{'Data'}->{'Results'}});
    }
    return (undef, $msg->{'Data'}->{'Results'});
}

sub send {
    my $self = shift;
    my $msg  = shift;
    
    $Logger->debug('encoding...');
    
    warn Dumper($msg);

    if($Logger->is_debug()){
        $msg = JSON::XS->new->pretty->convert_blessed(1)->encode($msg);
    } else {
        $msg = JSON::XS->new->convert_blessed(1)->encode($msg);
    }
    
    $Logger->debug('sending upstream...');
    
    $msg = $self->_send($msg);
    return 0 unless($msg);

    $Logger->debug('decoding...');
    $msg = JSON::XS->new->decode($msg);
    
    $msg = ${$msg}[0] if(ref($msg) && ref($msg) eq 'ARRAY');
    
    return $msg;
}

sub _send {
    my $self    = shift;
    my $msg     = shift;

    my ($ret,$err);
    $ret = $self->socket->send($msg);
    
    try {
        $ret = $self->socket->recv();
    } catch {
        $err = shift;
    };
    
    if($err){
        for($err){
            if(/Resource temporarily unavailable/){
                $Logger->debug('cif-router timeout...');
                # o/w queued msgs will hang the context thread
                $self->socket->set(ZMQ_LINGER,'int',0);
                return 0;
            }
            $Logger->error($err);
        }
    }
    
    return $ret;
}

sub submit_feed {
    my $self = shift;
    my $args = shift;
    
    return $self->_submit($args);
}

sub submit {
    my $self = shift;
    my $args = shift;
    
    map { $_ = CIF::ObservableFactory->new_plugin($_) } (@{$args->{'Observables'}});
    
    return $self->_submit($args);
}

sub _submit {
    my $self = shift;
    my $args = shift;
    
    my $msg = CIF::Message->new({
        rtype       => 'submission',
        mtype       => 'request',
        Token       => $args->{'Token'} || $self->Token(),
        Observables => $args->{'Observables'},
        Feed        => $args->{'Feed'},
    });
    
    my $sent = 1;
    if($args->{'Observables'}){
        $sent += ($#{$args->{'Observables'}});
    }
    $Logger->info('sending: '.($sent));
    
    my $t = gettimeofday();
    
    $msg = $self->send($msg);
    if($msg){
        $t = tv_interval([split(/\./,$t)]);
        $Logger->info('took: ~'.$t);
        $Logger->info('rate: ~'.($sent/$t).' o/s');
        return $msg->{'Data'} if($msg->{'stype'} eq 'failure');
        return (undef,$msg->{'Data'}->{'Results'});
    } else {
        $Logger->warn('send failed');
        return -1;
    }
}

__PACKAGE__->meta->make_immutable(inline_destructor => 0);    

1;