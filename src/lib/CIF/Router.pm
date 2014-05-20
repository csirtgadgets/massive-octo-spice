package CIF::Router;

use 5.011;
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
    
    init_logging({ level => 'ERROR'}) unless($Logger);
    
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
    
    $msg = JSON::XS::decode_json($msg);

    $msg = @{$msg}[0] if(ref($msg) eq 'ARRAY');
    
    my $r = CIF::Message->new({
        rtype   => $msg->{'@rtype'} || $msg->{'rtype'},
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