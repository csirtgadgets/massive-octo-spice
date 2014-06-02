package CIF::Smrt::Fetcher::Uri;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use Carp::Assert;
use Net::SSLeay;
use File::Path qw(make_path);
use File::Spec;
use CIF qw/$Logger/;
Net::SSLeay::SSLeay_add_ssl_algorithms();

with 'CIF::Smrt::Fetcher';

use constant DEFAULT_CAPACITY   => 5;
use constant DEFAULT_TLS_VERIFY => 1;
use constant DEFAULT_TIMEOUT    => 300;

has 'handle' => (
    is              => 'rw',
    reader          => 'get_handle',
    writer          => 'set_handle',
    isa             => 'LWP::UserAgent',
    lazy_build    => 1,
);

##TODO steal from CIF::Type::Uri
sub understands {
    my $self = shift;
    my $args = shift;

    return 0 unless($args->{'rule'}->{'remote'});
    return 1 if($args->{'rule'}->{'remote'} =~ /^(http|ftp|scp)/);
}

sub _build_handle {
    my $self = shift;
    my $args = shift;
    
    my $agent = LWP::UserAgent->new(
        agent       => DEFAULT_AGENT(),
        timeout     => $args->{'timeout'} || DEFAULT_TIMEOUT(),
        conn_cache  => { 
            total_capacity  => $args->{'capacity'} || DEFAULT_CAPACITY()
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

    $self->set_handle($agent);
}

sub process {
    my $self = shift;
    my $args = shift;
    
    my $tmp = $self->get_tmp().'/'.$self->get_rule()->get_defaults()->{'provider'}.'-'.$self->get_rule()->get_feed();
    assert(-w $tmp, 'temp space is not writeable by user, or file exists and is not owned by user: '.$tmp) if(-e $tmp);
    ##TODO -- umask
    
    my $ret;
    unless($self->get_test_mode() && -e $tmp){
        $Logger->debug('pulling: '.$self->get_rule()->get_remote());
        $ret = $self->get_handle()->mirror($self->get_rule()->get_remote(),$tmp);
        unless($ret->is_success() || $ret->status_line() =~ /^304 /){
            $Logger->error($ret->status_line());
            return $ret->decoded_content();
        }
    }
    return $self->process_file({ file => $tmp });
}

sub BUILD {
    my $self = shift;
    my $args = shift;
    
    make_path($self->get_tmp(), { mode => 0770 }) unless(-e $self->get_tmp());
}

__PACKAGE__->meta->make_immutable();

1;
