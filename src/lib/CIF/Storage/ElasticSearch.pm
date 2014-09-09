package CIF::Storage::ElasticSearch;

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
use CIF qw/hash_create_random is_hash_sha256 is_ip is_fqdn/;
use Data::Dumper;
use JSON qw(encode_json);

with 'CIF::Storage';

use constant DEFAULT_NODE               => 'localhost:9200';
use constant DEFAULT_MAX_FLUSH_COUNT    => 10000;

use constant OBSERVABLES_BASE           => 'cif.observables';
use constant FEEDS_BASE                 => 'cif.feeds';

use constant {
    OBSERVABLES_TYPE    => 'observables',
    FEEDS_TYPE          => 'feeds',
};

use constant DEFAULT_LIMIT              => 5000;

has 'handle' => (
    is          => 'rw',
    isa         => 'Search::Elasticsearch::Client::Direct',
    reader      => 'get_handle',
    writer      => 'set_handle',
    lazy_build  => 1,
);

has 'nodes' => (
    is      => 'ro',
    default => sub { [ DEFAULT_NODE() ] },
    reader  => 'get_nodes',
);

has 'observables_index'  => (
    is      => 'ro',
    default => sub { OBSERVABLES_BASE() },
);

has 'feeds_index' => (
    is      => 'ro',
    default => sub { FEEDS_BASE() },
);

has 'max_flush' => (
    is      => 'ro',
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
    
    warn ::Dumper($args);
    
    my $ret;
    if($args->{'Query'} && $args->{'feed'}){
    	$Logger->debug('searching for feed...');
    	$ret = $self->_feed($args);
    } elsif($args->{'Query'} || $args->{'Id'} || $args->{'Filters'}){
        $Logger->debug('searching...');
        $ret = $self->_search($args);
    } elsif($args->{'Observables'} || $args->{'Feed'}){
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
    
    my $groups = $args->{'group'} || ['everyone'];
    $groups = [$groups] unless(ref($groups) && ref($groups) eq 'ARRAY');
    
    my ($q,$terms,$ranges,$prefix,$regexp);
       
    if($args->{'Id'}){
    	$terms->{'id'} = [$args->{'Id'}];
    } elsif($args->{'Query'}) {
    	if($args->{'Query'} ne 'all'){
    		if(is_ip($args->{'Query'})){
                my @array = split(/\./,$args->{'Query'});
    		    $regexp->{'observable'} = $array[0].'.*';
    		} else {
    		    $terms->{'observable'} = [$args->{'Query'}];
    		}
    	}
    }
    
    my $filters = $args->{'Filters'};
    
    $Logger->debug(Dumper($filters));
    
    if($filters->{'otype'}){
    	$terms->{'otype'} = [$filters->{'otype'}];
	}
	my $missing;

	if($filters->{'cc'}){
		$terms->{'cc'} = [lc($filters->{'cc'})];
	} else {
	    if($args->{'feed'}){
	        $missing = { 'field' => 'cc' };
	    }
	}
    
    if($filters->{'confidence'}){
    	$ranges->{'confidence'}->{'gte'} = $filters->{'confidence'};
    }
    
    if($filters->{'starttime'}){
    	$ranges->{'reporttime'}->{'gte'} = $filters->{'starttime'};
    }
    
    if($filters->{'tags'}){
    	$filters->{'tags'} = [$filters->{'tags'}] unless(ref($filters->{'tags'}) eq 'ARRAY');
    	$terms->{'tags'} = $filters->{'tags'};
    }
    
    if($filters->{'application'}){
    	$filters->{'application'} = [$filters->{'application'}] unless(ref($filters->{'application'}) eq 'ARRAY');
    	$terms->{'application'} = $filters->{'application'};
    }
    
    if($filters->{'asn'}){
    	$filters->{'asn'} = [$filters->{'asn'}] unless(ref($filters->{'asn'}));
    	$terms->{'asn'} = $filters->{'asn'}
    }
    
    if($filters->{'provider'}){
        $filters->{'provider'} = [$filters->{'provider'}] unless(ref($filters->{'provider'}));
        $terms->{'provider'} = $filters->{'provider'}
    }
    
    ## TODO asn_desc TERM => ***
    
    if($filters->{'group'}){
        $filters->{'group'} = [$filters->{'group'}] unless(ref($filters->{'group'}) eq 'ARRAY');
    } else {
        $filters->{'group'} = ['everyone'];
    }
    
    $terms->{'group'} = $filters->{'group'};
    
    my (@and,@or);
    
    if($terms){
		foreach (keys %$terms){
			if($_ eq 'tags'){
				my @or;
                foreach my $e (@{$terms->{$_}}){
                    push(@or, { term => { $_ => [$e] } } );
                 }
                 push(@and,{ 'or' => \@or });
            } elsif($_ eq 'group') { ##TODO
                my @or;
                foreach my $e (@{$terms->{$_}}){
                	push(@or, { term => { $_ => [$e] } } );
                }
                push(@and, { 'or' => \@or });
            } else {
		      push(@and, { term => { $_ => $terms->{$_} } } );	
            }
		}
	}
	
	if($regexp){
	   foreach (keys %$regexp){
		    push(@and, { regexp => { $_ => $regexp->{$_} } } );
		}
	}
    
    if($ranges){
    	foreach (keys %$ranges){
    		push(@and, { range => { $_ => $ranges->{$_} } } );
    	}
    }
    
    if($missing){
        push(@and, { 'missing' => $missing } );
    }
    
    $q = {
		query => {
	    	filtered    => {
	        	filter  => {
	        		'and' => \@and,
	        	}
	        },
	    },
	    'sort' =>  [
            { '@timestamp' => { 'order' => 'desc'}},
        ],
	};
	
	if($Logger->is_debug()){
	    my $j = JSON->new();
        $Logger->debug($j->pretty->encode($q)); ##TODO -- debugging
	}
	
    my $index = $self->observables_index();
    if($args->{'feed'}){
        $filters->{'limit'} = 1;	
        $index = $self->feeds_index();
    }
    
    $index .= '-*';
    
    $Logger->debug('searching index: '.$index);
    
    my %search = (
        index   => $index,
        size    => $filters->{'limit'} || 5000, ##TODO
        body    => $q,
    );
    
    my $results = $self->get_handle()->search(%search);
    $results = $results->{'hits'}->{'hits'};
    
    $results = [ map { $_ = $_->{'_source'} } @$results ];
    
    if(is_ip($args->{'Query'})){
        $results = _ip_results($args->{'Query'},$results);
    } elsif(is_fqdn($args->{'Query'})){
        $results = _fqdn_results($args->{'Query'},$results);
    }
    
    if(defined($args->{'feed'})){
        $results = @{$results}[0]->{'Observables'};
    }
    
    return $results;
}

sub _ip_results {
    my $query = shift;
    my $results = shift;
    
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

sub _fqdn_results {
    my $query = shift;
    my $results = shift;
    
    my $t = Net::DNS::Match->new();
    $t->add($query);
    
    my @ret;
    foreach (@$results){
        push(@ret,$_) if($t->match($_->{'observable'}));
    }
    return \@ret;
}

sub _submission {
    my $self = shift;
    my $args = shift;
    
    my $timestamp = DateTime->from_epoch(epoch => time()); # this is for the record insertion ts
    my $date = $timestamp->ymd('.'); # for the index
    $timestamp = $timestamp->ymd().'T'.$timestamp->hms().'Z';
    
    my ($things,$index,$type);
    
    if($args->{'Observables'}){
        $things = $args->{'Observables'};
        $index = $self->observables_index();
        $type = 'observables';
    } else {
        $type = 'feed';
        $things = $args->{'Feed'};
        $index = $self->feeds_index(),
    }
    
    $index = $index.'-'.$date;
    
    my $id;
    my ($ret,$err);
   
    $Logger->debug('submitting to index: '.$index);
    
    my $bulk = Search::Elasticsearch::Bulk->new(
        es  => $self->get_handle(),
        index       => $index,
        type        => $type,
        max_count   => $self->get_max_flush(),
        verbose     => 1,
    );

    foreach (@$things){
        $_->{'@timestamp'}  = $timestamp;
        $_->{'@version'}    = 2; ##TODO
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

__PACKAGE__->meta()->make_immutable();

1;