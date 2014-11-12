package CIF::Router;

use strict;
use warnings;

use Mouse;
use CIF qw/init_logging $Logger/;
use CIF::Message;
use CIF::Router::RequestFactory;
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

has 'storage'   => (
    is          => 'ro',
    isa         => 'Str',
    reader      => 'get_storage',
);

has 'storage_handle'    => (
    is          => 'ro',
    lazy_build  => 1,
);

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
    
    unless($self->storage_handle->check_handle()){
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
                    
                    $Logger->info('decoding...');
                    $msg = JSON::XS->new->decode(@$msg);
                    $Logger->info('processing...');
                    try {
                        $msg = $self->process($msg);
                    } catch {
                        $err = shift;
                    };
                    
                    if($err){
                        $ret = -1;
                        $Logger->error($err);
                        $msg = CIF::Message->new({
                            stype   => 'failure',
                            mtype   => 'response',
                            rtype   => $msg->{'rtype'},
                            Data    => 'unknown failure',
                        });
                    } else {
                        $self->publish($msg) if($msg->{'stype'} eq 'success');
                    }
                        
                    $Logger->debug('re-encoding...');
                    
                    if($Logger->is_debug()){
                        $msg = JSON::XS->new->pretty->convert_blessed(1)->encode($msg);
                    } else {
                        $msg = JSON::XS->new->convert_blessed(1)->encode($msg);
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

    $msg = @{$msg}[0] if(ref($msg) eq 'ARRAY');
    
    my $r = CIF::Message->new({
        rtype   => $msg->{'rtype'},
        mtype   => 'response',
    });
    
    my $user = $self->storage_handle->check_auth($msg->{'Token'});

    if($user){
        my $req = CIF::Router::RequestFactory->new_plugin({ 
            msg     => $msg,
            storage => $self->storage_handle,
            user    => $user,
            nolog   => $msg->{'nolog'},
        });
        if($req){
            $Logger->debug('found request plugin: '.ref($req));
            my $rv = $req->process($msg->{'Data'});
            if($rv < 0){
                $Logger->error('request failure');
                $r->stype('failure');
                $r->Data('ERROR: contact administrator');
            } else {
                $r->Data($rv);
                $r->stype('success');
            }
        } else {
            $Logger->error('request type not supported');
            $r->stype('failure');
            $r->Data('ERROR: request type not supported');
        }
    } else {
        $Logger->info('auth failed for: '.$msg->{'Token'});
        $r->stype('unauthorized');
    }
    
    return $r;
}

sub publish {
    my $self = shift;
    my $m = shift;
    
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
        if(/^ping(-write)?$/){
            $m = undef;
            last;
        }
        if(/^token-/){
            $m = undef;
            last;
        }
        $m = [@{$m->{'Data'}->{'Results'}}];
    }
    
    if($m){
        $Logger->debug('publishing...');
        $m = JSON::XS::encode_json($m);
        $self->publisher->send($m);
    }
    $m = undef;
    return 1;
}

__PACKAGE__->meta->make_immutable();  

1;
