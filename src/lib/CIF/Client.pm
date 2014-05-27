package CIF::Client;

use strict;
use warnings;
use namespace::autoclean;

use CIF qw/init_logging $Logger/;
use CIF::Message;
use CIF::Client::BrokerFactory;
use CIF::FormatFactory;
use CIF::EncoderFactory;
use CIF::ObservableFactory;

use Mouse;
use Time::HiRes qw(tv_interval gettimeofday);
use Config::Simple;
use Data::Dumper;
use Carp::Assert;

has 'remote'    => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_remote',
);

has 'broker_handle' => (
    is          => 'ro',
    reader      => 'get_broker_handle',
    lazy_build  => 1,
);

has 'config'    => (
    is      => 'ro',
    isa     => 'Str',
    default => CIF::DEFAULT_CONFIG(),
);

has 'format' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'table',
    reader  => 'get_format',
    writer  => 'set_format',
);

has 'format_handle' => (
    is          => 'ro',
    reader      => 'get_format_handle',
    lazy_build  => 1,
);

has 'results'   => (
    is      => 'rw',
    isa     => 'ArrayRef',
);

has 'Token' => (
    is      => 'ro',
    isa     => 'Str',
);

has 'encoder'   => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_encoder',
);

has 'encoder_handle' => (
    is          => 'ro',
    reader      => 'get_encoder_handle',
    lazy_build  => 1,
);

has 'encoder_pretty'    => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_encoder_pretty',
);

sub _build_format_handle {
    my $self = shift;
    return CIF::FormatFactory->new_plugin($self->get_format());
}

sub _build_encoder_handle {
    my $self = shift;
    return CIF::EncoderFactory->new_plugin($self->get_encoder());
}

sub _build_broker_handle {
    my $self = shift;
    return CIF::Client::BrokerFactory->new_plugin($self->get_remote());
}

sub BUILD {
    my $self = shift;
    unless($Logger){
        init_logging({ level => 'WARN' });
    }
}



around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;

    $args->{'broker'}           = CIF::Client::BrokerFactory->new_plugin({ config => $args });
    return $self->$orig($args);
};

sub encode {
    my $self = shift;
    my $args = shift;
    
    return $self->get_encoder_handle()->encode({ 
        data => $args->{'data'}, encoder_pretty => $self->get_encoder_pretty() 
    });
}

sub decode {
    my $self = shift;
    my $data = shift;
    
    return $self->get_encoder_handle()->decode({ data => $data });
}

sub receive {
    my $self = shift;
    my $msg = $self->get_broker_handle()->receive();
    $msg = $self->decode($msg);
    map { $_ = CIF::ObservableFactory->new_plugin($_) } (@{$msg});
    return $msg;
}

sub subscribe {
	my $self = shift;
	my $cb = shift;
	
	return AnyEvent->io(
	   fh      => $self->get_broker_handle()->get_fd(),
	   poll    => 'r',
	   cb      => $cb,
    );
}

sub has_pollin {
    my $self = shift;
    return $self->get_broker_handle()->get_socket->has_pollin();
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
    
    my $msg = CIF::Message->new({
        rtype       => 'search',
        mtype       => 'request',
        Token       => $args->{'Token'} || $self->Token(),
        Query       => $args->{'Query'},
        confidence  => $args->{'confidence'},
        limit       => $args->{'limit'},
        group       => $args->{'group'},
        Tags        => $args->{'Tags'},
    });

    $msg = $self->send($msg);
    my $stype = $msg->{'stype'} || $msg->{'@stype'};
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

    $msg = $self->encode({ data => $msg });

    $Logger->debug('sending upstream...');
    
    $msg = $self->get_broker_handle()->send($msg);
    return 0 unless($msg);

    $Logger->debug('decoding...');
    $msg = $self->decode($msg);
    $msg = ${$msg}[0] if(ref($msg) && ref($msg) eq 'ARRAY');
    
    return $msg;
}

sub submit {
    my $self = shift;
    my $args = shift;

    map { $_ = CIF::ObservableFactory->new_plugin($_) } (@{$args->{'Observables'}});
    
    my $msg = CIF::Message->new({
        rtype       => 'submission',
        mtype       => 'request',
        Token       => $args->{'Token'} || $self->Token(),
        Observables => $args->{'Observables'},
    });
    
    my $sent = ($#{$args->{'Observables'}} + 1);
    $Logger->info('sending: '.($sent));
    my $t = gettimeofday();
    $msg = $self->send($msg);
    if($msg){
        $t = tv_interval([split(/\./,$t)]);
        $Logger->info('took: ~'.$t);
        $Logger->info('rate: ~'.($sent/$t).' o/s');
        return $msg->{'Data'} if($msg->{'@stype'} eq 'failure');
        return (undef,$msg->{'Data'}->{'Results'});
    } else {
        $Logger->warn('send failed');
        return -1;
    }
}

sub format {
    my $self = shift;
    my $args = shift;
    
    return '' unless(ref($args->{'data'}) eq 'ARRAY');
    return '' unless($#{$args->{'data'}} > -1);
    
    $Logger->info('formatting...');
    unless($self->get_format_handle()){
        assert($args->{'format'},'missing arg: format');
        $self->set_format_handle(CIF::FormatFactory->new_plugin($args));
    }
    return $self->get_format_handle()->process($args->{'data'});
}

sub shutdown {
    my $self = shift;
    if($self->get_broker_handle()){
        $self->get_broker_handle()->shutdown();
    }
    return 1;
}    

sub DESTROY {
    my $self = shift;
    $self->shutdown();
}

__PACKAGE__->meta->make_immutable(inline_destructor => 0);    

1;