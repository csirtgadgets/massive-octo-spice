package CIF::Router;

use 5.011;
use strict;
use warnings;

use Mouse;
use CIF qw/$Logger/;
use CIF::Message;
use CIF::Encoder::Json;
use CIF::Router::RequestFactory;
use CIF::Router::AuthFactory;
use CIF::StorageFactory;
use Config::Simple;
use ZMQx::Class;
use JSON::XS;
use Try::Tiny;

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

has 'auth_handle' => (
    is      => 'ro',
    reader  => 'get_auth_handle',
);

has 'storage_handle'    => (
    is      => 'ro',
    reader  => 'get_storage_handle',
);

has 'encoder_pretty'    => (
    is      => 'ro',
    isa     => 'Bool',
);

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;
    
    # if we're passed a config file
    if($args->{'config'}){
        unless(ref($args->{'config'})){
            $args->{'config'} = Config::Simple->new($args->{'config'});
        }
        %$args = %{$args->{'config'}->get_block('client')};
    }
    
    $args->{'auth_handle'}      = CIF::Router::AuthFactory->new_plugin($args->{'auth'});
    $args->{'storage_handle'}   = CIF::StorageFactory->new_plugin($args->{'storage'});
    
    return $self->$orig($args);
};

sub startup {
    my $self = shift;
    my $args = shift;
    
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
                    
                    $self->publish($msg);
                    
                    try {
                        $msg = $self->process(@$msg);
                    } catch {
                        $err = shift;
                    };
                    
                    if($err){
                        $ret = -1;
                        $Logger->error($err);
                    }
                    $Logger->debug('sending msg back...');
                    $self->frontend->send($msg);
                }
            }
        )
    );
    $Logger->info('router started...');
    return 1;
}

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

##TODO refactor
sub process {
    my $self = shift;
    my $msg = shift;
    
    ##todo encoder factory?
    $msg = JSON::XS::decode_json($msg);
    $msg = @{$msg}[0] if(ref($msg) eq 'ARRAY');
    
    my $r = CIF::Message->new({
        rtype   => $msg->{'@rtype'} || $msg->{'rtype'},
        mtype   => 'response',
        Token   => $msg->{'Token'},
    });
    
    my $ret = $self->get_auth_handle()->process($msg);
    if($ret){
        my $req = CIF::Router::RequestFactory->new_plugin({ 
            msg             => $msg,
            auth_handle     => $self->get_auth_handle(),
            storage_handle  => $self->get_storage_handle(),
        });
        if($req){
            my $rv = $req->process($msg);
            if($rv < 0){
                $r->set_stype('failure');
                $r->set_Data('ERROR: contact administrator');
            } else {
                $r->set_Data($rv);
                $r->set_stype('success');
            }
        } else {
            $r->set_stype('failure');
            $r->set_Data('ERROR: not supported');
        }
    } else {
        $r->set_stype('unauthorized');
        delete($r->{'Data'});
    }
    
    ##todo encoder factory?
    $r = CIF::Encoder::Json->encode({ 
        encoder_pretty  => 1,
        data            => $r 
    });
    return $r;
}

__PACKAGE__->meta->make_immutable();  

1;