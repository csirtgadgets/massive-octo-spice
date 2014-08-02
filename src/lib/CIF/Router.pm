package CIF::Router;

use strict;
use warnings;

use Mouse;
use CIF qw/init_logging $Logger/;
use CIF::Message;
use CIF::Encoder::Json;
use CIF::Router::RequestFactory;
use CIF::Router::AuthFactory;
use CIF::StorageFactory;
use Config::Simple;
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
    isa     => 'Int',
    default => DEFAULT_FRONTEND_PORT(),
);

has 'frontend_listen'   => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_FRONTEND_LISTEN(),
    reader  => 'get_frontend_listen',
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
    reader  => 'get_publisher',
);

has 'publisher_listen' => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_PUBLISHER_LISTEN(),
    reader  => 'get_publisher_listen',
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

has 'encoder_pretty'    => (
    is      => 'ro',
    isa     => 'Bool',
);

has 'refresh' => (
	is	=> 'ro',
	isa	=> 'Bool'
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
            bind => $self->get_frontend_listen(),
        )
    );
    $Logger->info('frontend started on: '.$self->get_frontend_listen());
    
    $self->publisher(
        ZMQx::Class->socket(
            'PUB',
            bind    => $self->get_publisher_listen(),
        )
    );
    
    $Logger->info('publisher started on: '.$self->get_publisher_listen());
    
    my ($ret,$err,$m);
    $self->frontend_watcher(
        $self->frontend->anyevent_watcher(
            sub {
                while (my $msg = $self->frontend->receive()){
                    $Logger->debug('received message...');
                    $Logger->trace(Dumper($msg));
                    
                    $Logger->debug('publishing');
                    $self->publish($msg);
                    
                    $Logger->debug('processing...');
                    try {
                        $msg = $self->process(@$msg);
                    } catch {
                        $err = shift;
                    };
                    
                    if($err){
                        $ret = -1;
                        $Logger->error($err);
                    }
                    $Logger->debug('replying...');
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
    
    if($self->refresh()){
    	$Logger->debug('refreshing...');
    	require Module::Refresh;
    	Module::Refresh->refresh;
    	$Logger->debug('done..');
    }
    
    $msg = JSON::XS::decode_json($msg);

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
    $r = CIF::Encoder::Json->encode({ 
        encoder_pretty  => 1,
        data            => $r 
    });
    return $r;
}

##TODO - publisher
sub publish {
    my $self = shift;
    my $data = shift;
    
    ##TODO -- clean this up, permissions, etc
    #debug('publishing...');
    #$m = JSON::XS::decode_json(@{$msg}[0]);
    #$m = [@{$m->{'Data'}->{'Observables'}}];
    #if($m){
    #    $m = JSON::XS::encode_json($m);
    #    $self->get_publisher->send($m);
    #}
    #$m = undef;
    return 1;
}

__PACKAGE__->meta->make_immutable();  

1;
