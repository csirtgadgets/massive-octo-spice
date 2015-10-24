package CIF::Client;

use strict;
use warnings;

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

use constant {
    SND_TIMEOUT => 120000,
    RCV_TIMEOUT => 120000,
    REMOTE      => 'tcp://localhost:'.CIF::DEFAULT_PORT
};

use constant {
    SEARCH_CONFIDENCE => 25,
};

has [qw(remote subscriber results token tlp_map)] => (
    is  => 'ro',
);

has 'enable_metadata' => (
    is => 'ro',
    default => 1
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

has 'decoder' => (
    is  => 'ro',
    default => sub { JSON::XS->new->convert_blessed; }
);

sub _build_socket {
    my $self = shift;
    
    my $socket = $self->context->socket(
        ($self->subscriber()) ? ZMQ_SUB : ZMQ_REQ
    );
    $socket->set(ZMQ_SNDTIMEO,'int',SND_TIMEOUT());
    $socket->set(ZMQ_RCVTIMEO,'int',RCV_TIMEOUT());
    $socket->subscribe('') if($self->subscriber());
    $socket->connect($self->remote || REMOTE);
    
    return $socket;
}

sub BUILD {
    my $self = shift;
    init_logging({ level => 'WARN' }) unless($Logger);
}

sub ping {
    my $self = shift;
    my $args = shift;

    if($args->{'timeout'}){
        $self->socket->set(ZMQ_RCVTIMEO,'int',$args->{'timeout'});
    }
    
    $Logger->info('generating ping request...');
    my $msg = CIF::Message->new({
        rtype   => 'ping',
        mtype   => 'request',
        Token   => $self->token || $args->{'token'},
    });
    $Logger->info('sending ping...');
    my $ret = $self->_send($msg);
    
    unless($ret){
        # timeout
        $self->{'socket'} = $self->_build_socket();
        return $ret;
    }
    
    return 0 if $ret->{'stype'} eq 'unauthorized';
    return [gettimeofday] if $ret->{'stype'} eq 'success';
}

sub ping_write {
    my $self = shift;
    my $args = shift;
    
    $Logger->info('generating ping request...');
    my $msg = CIF::Message->new({
        rtype   => 'ping-write',
        mtype   => 'request',
        Token   => $self->token || $args->{'token'},
    });
    $Logger->info('sending ping...');
    my $ret = $self->_send($msg);
    
    return 0 if $ret->{'stype'} eq 'unauthorized';
    return [gettimeofday] if $ret->{'stype'} eq 'success';
}

sub token_new {
    my $self = shift;
    my $args = shift;
    
    my $msg = CIF::Message->new({
        rtype   => 'token-new',
        mtype   => 'request',   
        Token   => $self->token,
        Data    => $args,
    });
    $msg = $self->_send($msg);
    my $stype = $msg->{'stype'} || $msg->{'stype'};
    return $msg->{'Data'} if($stype eq 'failure');
}

sub token_list {
    my $self = shift;
    my $args = shift;
    
    my $msg = CIF::Message->new({
        rtype       => 'token-list',
        mtype       => 'request',
        Token       => $self->token,
        Data        => $args,
    });
    
    $msg = $self->_send($msg);

    my $stype = $msg->{'stype'} || $msg->{'stype'};
    return $msg->{'Data'} if($stype eq 'failure');
}

sub token_delete {
    my $self = shift;
    my $args = shift;
    
    my $msg = CIF::Message->new({
        rtype       => 'token-delete',
        mtype       => 'request',
        Token       => $self->token,
        Data        => $args,
    });
    
    $msg = $self->_send($msg);
   
    my $stype = $msg->{'stype'} || $msg->{'stype'};
    return $msg->{'Data'} if($stype eq 'failure');
}


sub search {
    my $self = shift;
    my $args = shift;
    
    my $filters = $args->{'filters'};

    if($filters->{'firsttime'}){
    	unless($filters->{'firsttime'} =~ /^\d+$/){
    		$filters->{'firsttime'} =  DateTime::Format::DateParse->parse_datetime($filters->{'firsttime'});
    		$filters->{'firsttime'} = $filters->{'firsttime'}->epoch.'000'; #millis
    	}
    }
    
    if($filters->{'lasttime'}){
    	unless($filters->{'lasttime'} =~ /^\d+$/){
    		$filters->{'lasttime'} =  DateTime::Format::DateParse->parse_datetime($filters->{'lasttime'});
    		$filters->{'lasttime'} = $filters->{'lasttime'}->epoch.'000'; #millis
    	}
    }
    
    if($filters->{'tags'} && $filters->{'tags'} =~ /,/){
    	$filters->{'tags'} = [split(/,/,$filters->{'tags'})];
    }
    
    if($filters->{'group'} && $filters->{'group'} =~ /,/){
    	$filters->{'group'} = [split(/,/,$filters->{'group'})];
    }
    my $msg;
    if($args->{'id'}){
    	$msg = CIF::Message->new({
    		rtype      => 'search',
	        mtype      => 'request',
	        Token      => $args->{'token'} || $self->token,
	        Id         => $args->{'id'},
    	});
    } else {
    	$msg = CIF::Message->new({
	        rtype      => 'search',
	        mtype      => 'request',
	        Token      => $args->{'token'} || $self->token,
	        Query      => $args->{'query'},
	        Filters    => $filters,
	        nolog      => $args->{'nolog'},
	    });
    }
    
    $Logger->debug('sending search...');
    
    $msg = $self->_send($msg);
    
    return 0 if $msg->{'stype'} eq 'unauthorized';
    return unless $msg->{'stype'} eq 'success';
    
    my $err;
    
    unless($args->{'nodecode'}){
        foreach (@{$msg->{'Data'}->{'Results'}}){
            try {
                $_ = CIF::ObservableFactory->new_plugin($_);
            } catch {
                $err = shift;
            };
            if($err){
                $Logger->error($err);
                $Logger->info(Dumper($_));
                $err = undef;
            } else {
                if($self->tlp_map && keys($self->tlp_map)){
                    $_->{'tlp'} = $self->tlp_map->{$_->{'tlp'}};
                    if($_->{'alt_tlp'}){
                        $_->{'alt_tlp'} = $self->tlp_map->{$_->{'alt_tlp'}};
                    }
                }
            }
        }
    }
    return (undef, $msg->{'Data'}->{'Results'});
}

sub submit {
    my $self = shift;
    my $args = shift;
    
    my $enable_metadata = $self->enable_metadata();
    
    if(defined($args->{'enable_metadata'})){
        $enable_metadata = $args->{'enable_metadata'};
    }
    
    foreach (@{$args->{'observables'}}){
        $_->{'observable'} = lc($_->{'observable'});
        $_->{'observable'} =~ s/\s+$//; # trip right side whitespace
        if($enable_metadata){
            try {
                $self->_process_metadata($_);
            } catch {
                $Logger->error(shift);
                return -1;
            };
        }
        
        try {
            $_ = CIF::ObservableFactory->new_plugin($_);
        } catch {
            $Logger->info(Dumper($_));
            $Logger->error(shift);
            return -1;
        };
    }
    return $self->_submit($args);
}

sub _process_metadata {
    my $self = shift;
    my $data = shift;
    
    foreach my $p (@{$self->metadata_plugins}){
        next unless($p->understands($data));
        $Logger->debug($p);
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
    });
    
    my $sent = 1;
    if($args->{'observables'}){
        $sent += ($#{$args->{'observables'}});
    }
    $Logger->info('sending: '.($sent));
    
    my $t = gettimeofday();
    
    $msg = $self->_send($msg);
    
    if($msg){
        $t = tv_interval([split(/\./,$t)]);
        $Logger->info('took: ~'.$t);
        $Logger->info('rate: ~'.($sent/$t).' o/s');
        return $msg->{'Data'} if($msg->{'stype'} eq 'failure');
        return 0 if($msg->{'stype'} eq 'unauthorized');
        return(undef,$msg->{'Data'}->{'Results'});
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
    $msg = $self->decoder->decode($msg);
    
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