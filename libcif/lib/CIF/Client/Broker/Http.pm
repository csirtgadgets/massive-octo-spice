package CIF::Client::Broker::Http;

use warnings;
use strict;

use Mouse;
use Try::Tiny;
use CIF qw/debug/;

extends 'LWP::UserAgent';
with 'CIF::Client::Broker';

has 'capacity' => (
    is      => 'ro',
    isa     => 'Int',
    default => 5,
    reader  => 'get_capacity',
);

has 'tls_verify' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
    reader  => 'get_tls_verify',
);

sub understands {
    my ($self,$args) = @_;
    
    return 0 unless($args->{'remote'});
    return 0 unless($args->{'remote'} =~ /^http/);
    return 1;
}

sub init { return 1; }

sub BUILD {
    my $self    = shift;
    my $args    = shift;
    
    # setup custom stuff
    $self->agent($self->get_agent());
    $self->conn_cache({ total_capacity  => $self->get_capacity() });
    
    unless($self->get_tls_verify()){
        $self->ssl_opts(SSL_verify_mode => 'SSL_VERIFY_NONE');
        $self->ssl_opts(verify_hostname => 0);
    }
    if($args->{'proxy'}){
        $self->proxy(['http','https'],$args->{'proxy'});
    } else {
        $self->env_proxy();
    }
    $self->set_is_connected(1);
}

sub send {
    my $self = shift;
    my $data = shift || return;
    
    my ($err,$ret);
    my $x = 0;
    my $max_retries = $self->get_max_retries();
    
    do {
        debug('posting data...') if($::debug);
        try {
            $ret = $self->post($self->get_remote(),Content => $data);
        } catch {
            $err = shift;
        };
        if($err){
            for(lc($err)){
                if(/^server closed connection/){
                    debug('server closed the connection, retrying...') if($::debug);
                    $err = undef;
                    sleep(5);
                    last;
                }
                if(/connection refused/){
                    debug('server connection refused, retrying...') if($::debug);
                    $err = undef;
                    sleep(5);
                    last;
                }
                $x = $max_retries;
            }
        }
    } while(!$ret && ($x++ < $max_retries));
    ## TODO -- do we turn this into a re-submit?
    return('unknown, possible server timeout....') unless($ret);
    return($ret->status_line()) unless($ret->is_success());
    debug('data sent succesfully...') if($::debug);
    return(undef,$ret->decoded_content());
}

sub shutdown {
    return 1;
}

__PACKAGE__->meta->make_immutable();

1;
