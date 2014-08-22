package CIF::Smrt::Fetcher;

use strict;
use warnings;

use Mouse;
use CIF qw/$Logger hash_create_static/;
use File::Spec;

use LWP::UserAgent;
use Mouse;
use Carp::Assert;
use Net::SSLeay;
use File::Path qw(make_path);
use File::Spec;
use CIF qw/$Logger/;
use File::Slurp;
Net::SSLeay::SSLeay_add_ssl_algorithms(); ## TODO -- this needs cleaning up

use constant {
    CAPACITY   => 5,
    TLS_VERIFY => 1,
    TIMEOUT    => 300,
    AGENT => 'cif-smrt/'.CIF::VERSION().' ('.CIF::ORG().')',
};

has 'agent'     => (
    is      => 'ro',
    default => AGENT,
);

has [qw(rule test_mode tmp)] => (
    is      => 'ro'
);

has 'handle' => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_handle {
    my $self = shift;
    my $args = shift;
    
    my $agent = LWP::UserAgent->new(
        agent       => AGENT,
        timeout     => $args->{'timeout'} || TIMEOUT,
        conn_cache  => { 
            total_capacity  => $args->{'capacity'} || CAPACITY
        },
    );
    
    # set both just in case we have legacy stuff laying around
    if(defined($args->{'tls_verify'}) && !$args->{'tls_verify'}){
        $agent->ssl_opts(SSL_verify_mode => 'SSL_VERIFY_NONE');
        $agent->ssl_opts(verify_hostname => 0);
    }
       
    ##TODO clean this up from v1
    if($args->{'proxy'}){
        $agent->proxy(['http','https'],$args->{'proxy'});
    } else {
        $agent->env_proxy();
    }
    
    return $agent;
}

sub process {
    my $self = shift;
    my $args = shift;
    
    my $ret;
    unless($self->test_mode() && -e $self->tmp){ ## testmode cleans out the cache
        $Logger->debug('pulling: '.$self->rule->remote);
        #$ret = $self->handle->mirror($self->rule->remote,$self->tmp);
        #unless($ret->is_success() || $ret->status_line() =~ /^304 /){
        #    $Logger->error($ret->status_line());
        #    return $ret->decoded_content();
        #}
    }
    return read_file($self->tmp, binmode => ':raw');
}

__PACKAGE__->meta->make_immutable();

1;