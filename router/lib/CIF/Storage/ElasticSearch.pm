package CIF::Storage::ElasticSearch;

use 5.011;
use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use ElasticSearch;
use ElasticSearch::SearchBuilder;
use CIF qw/observable_type hash_create_random/;
use Net::Patricia;
use Net::DNS::Match;
use DateTime;
use Time::HiRes qw/tv_interval/;

with 'CIF::Storage';

my $date = DateTime->from_epoch(epoch => time());
$date = $date->ymd('.');

use constant DEFAULT_HOST           => 'localhost:9200';
use constant DEFAULT_INDEX_BASE     => 'logstash';
use constant DEFAULT_INDEX_SEARCH   => DEFAULT_INDEX_BASE().'-*';
use constant DEFAULT_TYPE           => 'observables';

has 'handle' => (
    is      => 'ro',
    isa     => 'ElasticSearch',
    default => sub { ElasticSearch->new(servers => DEFAULT_HOST()) },
    reader  => 'get_handle',
    lazy    => 1,
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

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'plugin'});
    return 1 if($args->{'plugin'} eq 'elasticsearch');
}

sub shutdown {}

sub process {
    my $self = shift;
    my $args = shift;
    
    my $ret;
    if($args->{'Query'}){
        $ret = $self->process_query($args);
    } elsif($args->{'Observables'}){
        $ret = $self->process_submission($args);
    }
    return $ret;
}

sub process_submission {
    my $self = shift;
    my $args = shift;
    
    my @objs = @{$args->{'Observables'}};
    my @results;
    
    my $timestamp = DateTime->from_epoch(epoch => time());
    $timestamp = $timestamp->ymd().'T'.$timestamp->hms().'Z';
    
    my $ret;
    foreach(@objs){
        $ret = $self->get_handle()->create(
            index   => $self->get_index(),
            type    => $self->get_type(),
            data    => {
                %$_,
                '@timestamp'    => $timestamp,
                '@version'      => 2,
            },
            
        );
        push(@results,$ret->{'_id'});
        $ret = undef;
    }
    return \@results;
}

sub process_query {
    my $self = shift;
    my $args = shift;

    my $otype = observable_type($args->{'Query'});
    my $queryb; my $cb; my $filterb;

    if($otype){
        for($otype){
            if(/^ip/){
                $queryb = _process_ip($args);
                $cb = *_process_ip_results;
                last();
            }
            if(/^fqdn$/){
                $queryb = _process_fqdn($args);
                $cb = *_process_fqdn_results;
                last();
            }
            $queryb = { message => $args->{'Query'} };
        }
    } else {
        $filterb = { tags => $args->{'Query'} };
    }
    
    $filterb = {
        %$filterb,
        group   => $args->{'group'},
    };

    my $results = $self->get_handle()->search(
        index   => $self->get_index_search(),
        size    => $args->{'limit'},
        filterb => $filterb,
        queryb => $queryb,
    );

    $results = $results->{'hits'}->{'hits'};
    $results = [ map { $_ = $_->{'_source'} } @$results ];
    
    if($cb){
        $results = $cb->({
            Query   => $args->{'Query'},
            Results => $results,
        });
    }
    return $results;
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