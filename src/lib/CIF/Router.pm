package CIF::Router;

use strict;
use warnings;

use Mouse;
use CIF qw/init_logging $Logger/;
use CIF::Message;
use CIF::Router::RequestFactory;
use CIF::Router::AuthFactory;
use CIF::StorageFactory;
use ZMQx::Class;
use JSON::XS;
use Try::Tiny;
use Data::Dumper;

# constants
use constant DEFAULT_FRONTEND_PORT          => CIF::DEFAULT_FRONTEND_PORT();
use constant DEFAULT_BACKEND_PORT           => CIF::DEFAULT_BACKEND_PORT();

use constant DEFAULT_FRONTEND_LISTEN        => 'tcp://*:'.DEFAULT_FRONTEND_PORT();
use constant DEFAULT_BACKEND_LISTEN         => 'tcp://*:'.DEFAULT_BACKEND_PORT();

use constant DEFAULT_PUBLISHER_PORT         => CIF::DEFAULT_PUBLISHER_PORT();
use constant DEFAULT_PUBLISHER_LISTEN       => 'tcp://*:'.DEFAULT_PUBLISHER_PORT();

has 'port'      => (
    is      => 'ro',
    default => DEFAULT_FRONTEND_PORT,
);

has 'frontend_listen'   => (
    is      => 'ro',
    default => DEFAULT_FRONTEND_LISTEN,
);

has 'frontend'  => (
    is  => 'rw',
    isa => 'ZMQx::Class::Socket',
);

has 'frontend_watcher'  => (
    is => 'rw',
);

has 'publisher' => (
    is      => 'rw',
    isa     => 'ZMQx::Class::Socket',
);

has 'publisher_listen' => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_PUBLISHER_LISTEN,
);

has 'auth' => (
    is          => 'ro',
    isa         => 'Str',
    reader      => 'get_auth',
);

has 'auth_handle' => (
    is          => 'ro',
    reader      => 'get_auth_handle',
    lazy_build  => 1,
);

has 'storage'   => (
    is          => 'ro',
    isa         => 'Str',
    reader      => 'get_storage',
);

has 'storage_handle'    => (
    is          => 'ro',
    reader      => 'get_storage_handle',
    lazy_build  => 1,
);

sub _build_auth_handle {
    my $self = shift;
    return CIF::Router::AuthFactory->new_plugin({ plugin => $self->get_auth() });
}

sub _build_storage_handle {
    my $self = shift;
    return CIF::StorageFactory->new_plugin({ plugin => $self->get_storage() });
}

sub BUILD {
    my $self = shift;
    
    init_logging({ level => 'ERROR'}) unless($Logger);
}

sub startup {
    my $self = shift;
    my $args = shift;
    
    unless($self->get_auth_handle()->check_handle()){
        $Logger->fatal('unable to start router, no auth handle...');
        return 0;
    }
    
    unless($self->get_storage_handle()->check_handle()){
        $Logger->fatal('unable to start router, no storage handle...');
        return 0;
    }
    
    $self->frontend(
        ZMQx::Class->socket(
            'REP',
            bind => $self->frontend_listen,
        )
    );
    $Logger->info('frontend started on: '.$self->frontend_listen);
    
    $self->publisher(
        ZMQx::Class->socket(
            'PUB',
            bind    => $self->publisher_listen,
        )
    );
    
    $Logger->info('publisher started on: '.$self->publisher_listen);
    
    my ($ret,$err,$m);
    $self->frontend_watcher(
        $self->frontend->anyevent_watcher(
            sub {
                while (my $msg = $self->frontend->receive()){
                    $Logger->info('received message...');
                    
                    $Logger->debug(Dumper($msg));
                    
                    $Logger->info('publishing');
                    $self->publish($msg);
                    
                    $Logger->info('processing...');
                    try {
                        $msg = $self->process(@$msg);
                    } catch {
                        $err = shift;
                    };
                    
                    if($err){
                        $ret = -1;
                        $Logger->error($err);
                    }
                    $Logger->info('replying...');
                    $self->frontend->send($msg);
                }
            }
        )
    );
    $Logger->info('router started...');
    return 1;
}

sub process {
    my $self    = shift;
    my $msg     = shift;
    
    $msg = JSON::XS->new->decode($msg);

    $msg = @{$msg}[0] if(ref($msg) eq 'ARRAY');
    
    my $r = CIF::Message->new({
        rtype   => $msg->{'rtype'},
        mtype   => 'response',
        Token   => $msg->{'Token'},
    });
    
    $Logger->debug('auth');

    my $ret = $self->get_auth_handle()->process($msg);
    if($ret){
        $Logger->debug('auth passed');
        my $req = CIF::Router::RequestFactory->new_plugin({ 
            msg             => $msg,
            auth_handle     => $self->get_auth_handle(),
            storage_handle  => $self->get_storage_handle(),
        });
        if($req){
            $Logger->debug('found request plugin, processing...');
            my $rv = $req->process($msg);
            if($rv < 0){
                $Logger->error('request plugin failure');
                $r->set_stype('failure');
                $r->set_Data('ERROR: contact administrator');
            } else {
                $r->set_Data($rv);
                $r->set_stype('success');
            }
        } else {
            $Logger->error('request type not supported');
            $r->set_stype('failure');
            $r->set_Data('ERROR: request type not supported');
        }
    } else {
        $Logger->info('auth failed for: '.$msg->{'Token'});
        $r->set_stype('unauthorized');
        delete($r->{'Data'});
    }
    
    $Logger->debug('re-encoding...');

    if($Logger->is_debug()){
        return JSON::XS->new->pretty->convert_blessed(1)->encode($r);
    } else {
        return JSON::XS->new->convert_blessed(1)->encode($r);
    }
}

sub publish {
    my $self = shift;
    my $data = shift;
    
    $Logger->debug('publishing...');

    my ($m,$err);
    try {
        $m = JSON::XS->new->decode(@{$data}[0]);
    } catch {
        $err = shift;
        $Logger->error($err);
        $Logger->debug(Dumper($data));
    };
    
    return unless($m->{'mtype'} eq 'request');

    for($m->{'rtype'}){
        if(/^search$/){
            if($m->{'Data'}->{'Query'}){
                $m = [{observable => $m->{'Data'}->{'Query'}, confidence => 50, tags => ['search']}]; ##TODO
                last;
            }
            $m = undef;
            last;
        }
        if(/^submission$/){
            $m = $m->{'Data'}->{'Observables'};
            last;   
        }
        if(/^ping$/){
            $m = undef;
            last;
        }
        $m = [@{$m->{'Data'}->{'Results'}}];
    }
    
    if($m){
        $m = JSON::XS::encode_json($m);
        $self->publisher->send($m);
    }
    $m = undef;
    return 1;
}

__PACKAGE__->meta->make_immutable();  

1;
