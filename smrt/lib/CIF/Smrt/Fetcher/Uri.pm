package CIF::Smrt::Fetcher::Uri;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use MouseX::Foreign qw(LWP::UserAgent);

# cif stuff
use CIF::Type;

use Net::SSLeay;
Net::SSLeay::SSLeay_add_ssl_algorithms();

with 'CIF::Smrt::Fetcher';

has 'capacity' => (
    is      => 'ro',
    isa     => 'Int',
    default => 5,
);

has 'tls_verify' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
    reader  => 'get_tls_verify',
);

##TODO steal from CIF::Type::Uri
sub understands {
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'feed'});
    return 1 if($args->{'feed'} =~ /^(http|ftp|scp)/);
}

sub process {
    my $self = shift;
    my $args = shift;
    
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    return $self->$orig(%args);
};

sub BUILD {
    my $self    = shift;
    my $args    = shift;
  
    # setup custom stuff
    $self->agent(DEFAULT_AGENT());
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
}

__PACKAGE__->meta->make_immutable();

1;