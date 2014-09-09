package CIF::Client;

use strict;
use warnings;

use Data::Dumper;
use Mouse;
use CIF qw/init_logging $Logger normalize_timestamp/;
use CIF::Message;
use CIF::ObservableFactory;
use CIF::MetaFactory;
use JSON::XS;

use Time::HiRes qw(tv_interval gettimeofday);
use Data::Dumper;
use Carp::Assert;
use Try::Tiny;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_SUB ZMQ_SNDTIMEO ZMQ_RCVTIMEO ZMQ_LINGER);

use constant SND_TIMEOUT    => 120000;
use constant RCV_TIMEOUT    => 120000;
use constant REMOTE_DEFAULT => 'tcp://localhost:'.CIF::DEFAULT_PORT();

has [qw(remote subscriber results token)] => (
    is  => 'ro',
);

has [qw(context socket)] => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_context {
    return ZMQ::FFI->new();
}

has 'metadata_plugins'  => (
    is      => 'ro',
    default => sub { [ CIF::MetaFactory::_metadata_plugins() ] },
);

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

sub search {
    my $self = shift;
    my $args = shift;
    
    my $filters = $args->{'filters'};
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
    if($args->{'id'}){
    	$msg = CIF::Message->new({
    		rtype      => 'search',
	        mtype      => 'request',
	        Token      => $args->{'token'} || $self->token,
	        Id         => $args->{'id'},
	        feed       => $args->{'feed'},
    	});
    } else {
    	$msg = CIF::Message->new({
	        rtype      => 'search',
	        mtype      => 'request',
	        Token      => $args->{'token'} || $self->token(),
	        Query      => $args->{'query'},
	        Filters    => $filters,
	        feed       => $args->{'feed'},
	    });
    }
    $msg = $self->_send($msg);
    
    #$Logger->debug(Dumper($msg));
    
    my $stype = $msg->{'stype'} || $msg->{'stype'};
    return $msg->{'Data'} if($stype eq 'failure');
    
    unless($args->{'nodecode'}){
        map { $_ = CIF::ObservableFactory->new_plugin($_) } (@{$msg->{'Data'}->{'Results'}});
    }
    return (undef, $msg->{'Data'}->{'Results'});
}

sub submit_feed {
    my $self = shift;
    my $args = shift;
    
    return $self->_submit($args);
}

sub submit {
    my $self = shift;
    my $args = shift;
    
    ##TODO this should be spun out to a queue and returned quickly
    foreach (@{$args->{'observables'}}){
        $self->_process_metadata($_) if($args->{'enable_metadata'});
        $_ = CIF::ObservableFactory->new_plugin($_);
    }
    return $self->_submit($args);
}

sub _process_metadata {
    my $self = shift;
    my $data = shift;
    
    foreach my $p (@{$self->metadata_plugins}){
        next unless($p->understands($data));
        $p->new()->process($data);
    }
}

sub _submit {
    my $self = shift;
    my $args = shift;
    
    my $msg = CIF::Message->new({
        rtype       => 'submission',
        mtype       => 'request',
        Token       => $args->{'token'} || $self->token() || $self->{'Token'},
        Observables => $args->{'observables'},
        Feed        => $args->{'feed'},
    });
    
    my $sent = 1;
    if($args->{'Observables'}){
        $sent += ($#{$args->{'Observables'}});
    }
    $Logger->info('sending: '.($sent));
    
    my $t = gettimeofday();
    
    $msg = $self->_send($msg);
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

sub _send {
    my $self = shift;
    my $msg  = shift;
    
    $Logger->debug('encoding...');
    
    if($Logger->is_debug()){
        $msg = JSON::XS->new->pretty->convert_blessed(1)->encode($msg);
    } else {
        $msg = JSON::XS->new->convert_blessed(1)->encode($msg);
    }
    
    $Logger->debug('sending upstream...');
    
    my ($ret,$err);
    $ret = $self->socket->send($msg);
    
    try {
        $msg = $self->socket->recv;
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
            $Logger->critical($err);
            return 0;
        }
    }
    
    $Logger->debug('decoding...');
    $msg = JSON::XS->new->decode($msg);
    
    $msg = ${$msg}[0] if(ref($msg) && ref($msg) eq 'ARRAY');
    
    return $msg;
}

sub _subscribe {
	my $self = shift;
	my $cb = shift;
	
	return AnyEvent->io(
	   fh      => $self->socket->get_fd(),
	   poll    => 'r',
	   cb      => $cb,
    );
}

__PACKAGE__->meta->make_immutable(inline_destructor => 0);    

1;