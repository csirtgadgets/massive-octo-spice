package CIF::Storage::ElasticSearch;

use 5.011;
use strict;
use warnings;

use Mouse;
use Search::Elasticsearch;
use Search::Elasticsearch::Bulk;
use CIF qw/observable_type hash_create_random init_logging $Logger/;
use Net::Patricia;
use Net::DNS::Match;
use DateTime;
use Try::Tiny;
use Carp::Assert;
use CIF qw/hash_create_random is_hash_sha256/;

with 'CIF::Storage';

my $date = DateTime->from_epoch(epoch => time());
$date = $date->ymd('.');

use constant DEFAULT_NODE               => 'localhost:9200';
use constant DEFAULT_INDEX_BASE         => 'cif';
use constant DEFAULT_INDEX_SEARCH       => DEFAULT_INDEX_BASE().'-*';
use constant DEFAULT_TYPE               => 'observables';
use constant DEFAULT_LIMIT              => 500;
use constant DEFAULT_SEARCH_FIELD       => 'observable';
use constant DEFAULT_MAX_CONFIDENCE     => 100;
use constant DEFAULT_MAX_FLUSH_COUNT    => 10000;

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
    default => sub { DEFAULT_INDEX_BASE().'-'.$date },
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

has 'max_flush' => (
    is      => 'ro',
    isa     => 'Int',
    default => DEFAULT_MAX_FLUSH_COUNT(),
    reader  => 'get_max_flush',
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

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;
    
    init_logging({ level => 'ERROR'}) unless($Logger);
    
    return $self->$orig($args);
};

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
    
    my $ret;
    if($args->{'Query'}){
        $Logger->debug('searching...');
        $ret = $self->_search($args);
    } elsif($args->{'Observables'}){
        $Logger->debug('submitting...');
        $ret = $self->_submission($args);
    } else {
        $Logger->error('unknown type, skipping');
    }
    return $ret;
}

sub _search {
    my $self = shift;
    my $args = shift;
    
    return -1 if(ref($args->{'Query'}));
    
    my $groups = $args->{'groups'} || ['everyone'];
    $groups = [$groups] unless(ref($groups) && ref($groups) eq 'ARRAY');

    foreach (@$groups) {
        $_ = { "term" => { 'group' => $_ } };
    }
    
    my $q = $args->{'Query'};
    
    $q = [ split(/\//,$q) ];
    unshift(@{$q}, DEFAULT_SEARCH_FIELD()) unless($#{$q} > 0);
    my ($f,$v) = @$q;
    my $terms = [ split(/,/,$v) ];
    foreach (@$terms){
        $_ = { "term" => { $f => $_ } };
    }
    $q = {
        query => {
            filtered    => {
                filter  => {
                    "and"   => [
                        @$terms,
                    ],                      
                },
            },
        }         
    };
    
    if($args->{'confidence'}){
        push(@{$q->{'query'}->{'filtered'}->{'filter'}->{'and'}},
            { range => { "confidence" => { 'from' => $args->{'confidence'}, 'to' => DEFAULT_MAX_CONFIDENCE() } } }
        );
    }
    
    push(@{$q->{'query'}->{'filtered'}->{'filter'}->{'and'}},
        filter => { "or" => $groups },
    );
    
    my %search = (
        index   => $self->get_index_search(),
        size    => $args->{'limit'} || DEFAULT_LIMIT(),
        body    => $q,
    );
    
    my $results = $self->get_handle()->search(%search);
    $results = $results->{'hits'}->{'hits'};
    
    ##http://www.perlmonks.org/?node_id=743445
    ##http://search.cpan.org/dist/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitMutatingListFunctions.pm
    $results = [ map { $_ = $_->{'_source'} } @$results ];

    return $results;
}

sub _submission {
    my $self = shift;
    my $args = shift;
    
    $Logger->debug(Dumper($args));
    
    my @objs = @{$args->{'Observables'}};
    my @results;

    ##TODO
    my $timestamp = DateTime->from_epoch(epoch => time());
    $timestamp = $timestamp->ymd().'T'.$timestamp->hms().'Z';
    
    my $id;
    my ($ret,$err);
    my $bulk = Search::Elasticsearch::Bulk->new(
        es  => $self->get_handle(),
        index       => $self->get_index(),
        type        => $self->get_type(),
        max_count   => $self->get_max_flush(),
        verbose     => 1,
    );

    $Logger->debug(Dumper($bulk));
    foreach (@objs){
        $_->{'@timestamp'}  = $timestamp;
        $_->{'@version'}    = 2;
        $_->{'id'}  = hash_create_random();
        $bulk->index({ 
            id      => $_->{'id'}, 
            source => $_ ,
        });
    }

    $ret = $bulk->flush();
    
    ##http://www.perlmonks.org/?node_id=743445
    ##http://search.cpan.org/dist/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitMutatingListFunctions.pm
    $ret = [ map { $_ = $_->{'index'}->{'_id'} } @{$ret->{'items'}} ];
    return $ret;
}

##TODO -- factory?
sub _process_ip {
    my $args = shift;
    
    my @array = split(/\./,$args->{'Query'});
 
    return {
        observable => {
            wildcard => { value => $array[0].'.'.'*' },
        }
    }  
}

sub _process_ip_results {
    my $args = shift;
    
    my $query   = $args->{'Query'};
    my $results = $args->{'Results'};
    
    my $pt = Net::Patricia->new();
    $pt->add_string($query);
    my @ret; my $pt2;
    foreach (@$results){
        if($pt->match_string($_->{'observable'})){
            push(@ret,$_);
        } else {
            $pt2 = Net::Patricia->new();
            $pt2->add_string($_->{'observable'});
            push(@ret,$_) if($pt2->match_string($query));
        }
    }
    
    return \@ret;
}

sub _process_fqdn_results {
    my $args = shift;
    
    my $query   = $args->{'Query'},
    my $results = $args->{'Results'},
    
    my $t = Net::DNS::Match->new();
    $t->add($args->{'Query'});
    
    my @ret;
    foreach (@$results){
        push(@ret,$_) if($t->match($_->{'observable'}));
    }
    return \@ret;
}


sub _process_fqdn {
    my $args = shift;
    my $q = $args->{'Query'};
    
    return {
        observable => {
            wildcard => { value => '*'.$q },
        }
    }
}

__PACKAGE__->meta()->make_immutable();

1;