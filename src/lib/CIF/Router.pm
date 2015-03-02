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
use POSIX ":sys_wait_h";
use Data::Dumper;

# constants
use constant DEFAULT_FRONTEND_PORT          => CIF::DEFAULT_FRONTEND_PORT();
use constant DEFAULT_BACKEND_PORT           => CIF::DEFAULT_BACKEND_PORT();

use constant DEFAULT_FRONTEND_LISTEN        => 'tcp://*:'.DEFAULT_FRONTEND_PORT();
use constant DEFAULT_BACKEND_LISTEN         => 'tcp://*:'.DEFAULT_BACKEND_PORT();

use constant DEFAULT_PUBLISHER_PORT         => CIF::DEFAULT_PUBLISHER_PORT();
use constant DEFAULT_PUBLISHER_LISTEN       => 'tcp://*:'.DEFAULT_PUBLISHER_PORT();

use constant BACKEND => 'ipc:///tmp/cif-router-backend.ipc';

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
);

has 'storage_handle'    => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_storage_handle {
    my $self = shift;
    return CIF::StorageFactory->new_plugin({ plugin => $self->storage });
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
    
    my ($err,$resp,$msg, $encoder);
    
    if($Logger->is_debug()){
        $encoder = JSON::XS->new->pretty->convert_blessed(1);
    } else {
        $encoder = JSON::XS->new->convert_blessed(1);
    }
    $self->frontend_watcher(
        $self->frontend->anyevent_watcher(
            sub {
                while ($msg = $self->frontend->receive()){
                    $Logger->info('received message...');

                    $Logger->info('decoding...');
                    
                    my $backend = ZMQx::Class->socket('PULL', bind => BACKEND);
                    
                    $SIG{CHLD} = sub { };
                    my $child = fork();
                    
                    if($child == 0){
                        my $socket = ZMQx::Class->socket('PUSH', connect => BACKEND);
                        $Logger->debug(Dumper($msg));
                        $msg = $encoder->decode(@$msg);
                        $Logger->info('processing rtype: '.$msg->{'rtype'});
                        
                        try {
                            $Logger->debug(Dumper($msg));
                            $resp = $self->process($msg);
                            $Logger->debug('sending resp...');
                            $Logger->debug(Dumper($resp));
                            $socket->send($encoder->encode($resp));
                        } catch {
                            $err = shift;
                            $socket->send($err);
                        };
                    } else {
                        # parent
                        my $endtime = time() + 300;
                        my $pid;
                        undef $msg;
                        while (1) {
                            $msg = $backend->receive('blocking');

                            $Logger->debug(Dumper($msg));
                            $msg = @$msg[0] if(ref($msg) eq 'ARRAY');
                            $Logger->debug(Dumper($msg));
                            $msg = $encoder->decode($msg);
                        
                            my $tosleep = $endtime - time();
                         
                            $pid = waitpid(-1, WNOHANG);
                            last unless($tosleep > 0);
                            last if($pid > 0);
                            last if($msg);
                        }
                        if ($pid <= 0){
                            $Logger->error('child timed out!');
                            kill 9, $child;
                        }  else {
                            $Logger->debug(Dumper($msg));
                        }
                        
                        if($err){
                            $Logger->error($err);
                            $resp = CIF::Message->new({
                                stype   => 'failure',
                                mtype   => 'response',
                                rtype   => $msg->{'rtype'},
                                Data    => 'unknown failure',
                            });
                            $err = undef;
                        } else {
                            if(($msg->{'Data'}->{'Observables'} || $msg->{'Data'}->{'Query'}) && $msg->{'stype'} eq 'success'){
                                $Logger->info('publishing to subscribers...');
                                $self->publish($msg);
                                
                            } else {
                                $Logger->info('skipping subscriber publish..');
                            }
                            $resp = $msg;
                        }
                            
                        $Logger->debug('re-encoding...');
                        $resp = $encoder->encode($resp);
                      
                        $Logger->info('replying...');
                        $Logger->debug(Dumper($resp));
                        $self->frontend->send($resp);
                        
                        undef $resp;
                        undef $msg;
                        undef $err;
                    }
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
    
    my $user;
    if($msg->{'Token'} && lc($msg->{'Token'}) =~ /^[a-z0-9]{64}$/){
        $user = $self->storage_handle->check_auth($msg->{'Token'});
    }
    
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
            } elsif ($rv == 0) {
                $Logger->info('auth failed for: '.$msg->{'Token'});
                $r->stype('unauthorized');
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
        $Logger->info('auth failed');
        $Logger->debug('Token: '.$msg->{'Token'}) if($user);
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
