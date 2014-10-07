package CIF::Router::Auth::ElasticSearch;

use strict;
use warnings;

use Mouse;
use Search::Elasticsearch;
use Search::Elasticsearch::Bulk;
use CIF qw/init_logging $Logger/;
use DateTime;
use Try::Tiny;
use Carp::Assert;
use CIF qw/hash_create_random is_hash_sha256/;
use Data::Dumper;
use JSON qw(encode_json);

with 'CIF::Storage';

use constant {
    NODE    => 'localhost:9200',
    INDEX   => 'cif.tokens',
    TYPE    => 'tokens',
};

has 'handle' => (
    is          => 'rw',
    isa         => 'Search::Elasticsearch::Client::Direct',
    lazy_build  => 1,
);

has 'nodes' => (
    is      => 'ro',
    default => sub { [ NODE ] },
);

has 'index' => (
    is      => 'ro',
    default => sub { INDEX },
);

has 'type' => (
    is      => 'ro',
    default => sub { TYPE },
);

sub _build_handle {
    my $self = shift;
    my $args = shift;
 
    $self->handle(
        Search::Elasticsearch->new(
            nodes   => $self->nodes(),
        )
    );
}

sub BUILD {
    my $self = shift;
    init_logging({ level => 'ERROR'}) unless($Logger);
}

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'plugin'});
    return 1 if($args->{'plugin'} eq 'elasticsearch');
}

sub shutdown {}

sub check_handle {
    my $self = shift;

    $Logger->debug('checking handle...');
    my ($ret,$err);
    try {
        $self->handle->info();
    } catch {
        $err = shift;
    };
    
    if($err){
        $Logger->fatal($err);
        return 0;
    } else {
        $Logger->debug('handle check OK');
        return 1;
    }
}

sub process {
    my $self    = shift;
    my $msg     = shift;
    
    return -1 unless($self->check_handle());

    my $ret;
    for($msg->{'rtype'}){
        if(/^token-create$/){
            $Logger->debug('creating token...');
            return $self->create($msg);
        }
        if(/^token-list$/){
            $Logger->debug('searching for token...');
            return $self->search($msg);
        }
    }
}

sub auth { return shift->search(shift); }

sub search {
	my $self = shift;
	my $args = shift;
	
	my $data = $args->{'Data'};
	
	#return 1;
	warn Dumper($args);
	my $q;
	if($args->{'token'}){
	    $q = "token(\"$data->{'Token'}\")";
	} else {
	    # alias
	    $q = "token(\"$data->{'Alias'}\")";
	}
	
	$q = {
	    query  => {
	        query_string   => {
	            query  => $q
	        }
	    }
	};
	
	if($Logger->is_debug()){
	    my $j = JSON->new();
        $Logger->debug($j->pretty->encode($q)); ##TODO -- debugging
	}
	
	my %search = (
	   index   => $self->index,
	   body    => $q,
    );
    
    my $res = $self->handle->search(%search);
    $res = $res->{'hits'}->{'hits'};
    $res = [ map { $_ = $_->{_source} } @$res ];
    warn Dumper($res);
    
    return $res;
}

sub create {
	my $self = shift;
	my $data = shift;
	
	my $token = hash_create_random();
	
	my $prof = {
	       alias   => 'wes@barely3am.com',
	       token   => $token,
	       admin   => 1,
	};
	
	my $res = $self->handle->index(
	   index   => $self->index,
	   id      => hash_create_random(),
	   type    => $self->type,
	   body    => $prof
    );
    return $token if($res->{_id});
}

sub remove {
    my $self = shift;
    my $data = shift;
    
        
	
}



__PACKAGE__->meta()->make_immutable();

1;