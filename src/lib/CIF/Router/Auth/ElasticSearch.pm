package CIF::Auth::ElasticSearch;

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

use constant DEFAULT_NODE               => 'localhost:9200';
use constant DEFAULT_INDEX_BASE         => 'ciftokens';
use constant DEFAULT_TYPE               => 'tokens';
use constant DEFAULT_SEARCH_FIELD       => 'token';

has 'handle' => (
    is          => 'rw',
    isa         => 'Search::Elasticsearch::Client::Direct',
    reader      => 'get_handle',
    writer      => 'set_handle',
    lazy_build  => 1,
);

has 'nodes' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [ DEFAULT_NODE() ] },
    reader  => 'get_nodes',
);

has 'index' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { DEFAULT_INDEX_BASE() },
    reader  => 'get_index',
);

has 'index_search'  => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { DEFAULT_INDEX_SEARCH() },
    reader  => 'get_index_search',
);

has 'type'  => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { DEFAULT_TYPE() },
    reader  => 'get_type',
);

sub _build_handle {
    my $self = shift;
    my $args = shift;
 
    $self->set_handle(
        Search::Elasticsearch->new(
            nodes   => $self->get_nodes(),
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
        $self->get_handle->info();
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

sub ping {
    my $self = shift;
    my $args = shift;
    
    return 1 if($self->check_handle());
    return 0;
}

sub process {
    my $self = shift;
    my $args = shift;
    
    return -1 unless($self->check_handle());
    
#    my $ret;
#    if($args->{'Query'} || $args->{'Id'} || $args->{'Filters'}){
#        $Logger->debug('searching...');
#        $ret = $self->_search($args);
#    } elsif($args->{'Observables'}){
#        $Logger->debug('submitting...');
#        $ret = $self->_submission($args);
#    } else {
#        $Logger->error('unknown type, skipping');
#    }
#    return $ret;
}

sub auth {
	
}

sub create {
	
}

sub remove {
	
}



__PACKAGE__->meta()->make_immutable();

1;