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
use CIF qw/hash_create_random is_hash_sha256 is_ip is_fqdn normalize_timestamp/;
use Data::Dumper;
use JSON qw(encode_json);
use Time::HiRes qw(gettimeofday);

with 'CIF::Storage';

use constant {
    NODE                => 'localhost:9200',
    MAX_SIZE            => 104857600,
    MAX_COUNT           => 5000000,
    OBSERVABLES         => 'cif.observables',
    FEEDS               => 'cif.feeds',
    OBSERVABLES_TYPE    => 'observables',
    FEEDS_TYPE          => 'feeds',
    LIMIT               => 50000,
    
    TOKENS_INDEX        => 'cif.tokens',
    TOKENS_TYPE         => 'tokens',
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

has 'observables_index'  => (
    is      => 'ro',
    default => sub { OBSERVABLES },
);

has 'feeds_index' => (
    is      => 'ro',
    default => sub { FEEDS },
);

has 'max_count' => (
    is      => 'ro',
    default => MAX_COUNT,
);

has 'max_size' => (
    is      => 'ro',
    default => MAX_SIZE,
);

has 'tokens_index'  => (
    is  => 'ro',
    default => sub { TOKENS_INDEX },
);

has 'tokens_type'  => (
    is  => 'ro',
    default => sub { TOKENS_TYPE },
);

sub _build_handle {
    my $self = shift;
    my $args = shift;
 
    $self->handle(
        Search::Elasticsearch->new(
            nodes   => $self->nodes,
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

sub ping {
    my $self = shift;
    my $args = shift;
    
    return 1 if($self->check_handle());
    return 0;
}

sub check_auth {
    my $self    = shift;
    my $token   = shift;
    
    return 0 unless $token;
    
    $Logger->debug('checking auth for: '.$token);
    
    my $q = { query => { query_string => { query => { default_field => 'token', query => $token } } } };
    
    if($Logger->is_debug()){
	    my $j = JSON->new();
        $Logger->trace($j->pretty->encode($q));
	}
    
    my %search = (
        index   => $self->tokens_index,
        body    => $q,
    );
    
    my $res = $self->handle->search(%search);

    return 0 if($res->{'hits'}->{'total'} == 0);
    
    $res = $res->{'hits'}->{'hits'};
    $res = @{$res}[0]->{'_source'};
    
    if($res->{'expires'}){
        my $dt = DateTime->from_epoch(epoch => time());
        $dt = $dt->ymd().'T'.$dt->hms().'Z';
        if($res->{'expires'} < $dt){
            $Logger->info('token is expired: '.$token);
            return 0;
        }
    }
    return $res;
}

sub process {
    my $self = shift;
    my $args = shift;
    
    unless($self->check_handle()){
        $Logger->warn('storage handle check failed...');
        return -1;
    } else {
        $Logger->info('storage handle OK');
    }
    
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
    
    my $groups = $args->{'group'};
    $groups = [$groups] unless(ref($groups) && ref($groups) eq 'ARRAY');
    
    my ($q,$terms,$ranges,$prefix,$regexp);
       
    if($args->{'Id'}){
    	$terms->{'id'} = [$args->{'Id'}];
    } elsif($args->{'Query'}) {
    	if($args->{'Query'} ne 'all'){
    		if(is_ip($args->{'Query'})){
                my @array = split(/\./,$args->{'Query'});
    		    $regexp->{'observable'} = $array[0].'.*';
    		    $terms->{'otype'} = 'ipv4'; ## TODO ipv6
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
	}
    
    if($filters->{'confidence'}){
    	$ranges->{'confidence'}->{'gte'} = $filters->{'confidence'};
    }
    
    if($filters->{'firsttime'}){
    	$ranges->{'firsttime'}->{'gte'} = $filters->{'firsttime'};
    }
    
    if($filters->{'lasttime'}){
    	$ranges->{'lasttime'}->{'lte'} = $filters->{'lasttime'};
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
    
    if($filters->{'rdata'}){
        $filters->{'rdata'} = [$filters->{'rdata'}] unless(ref($filters->{'rdata'}));
        $terms->{'rdata'} = $filters->{'rdata'}
    }

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
        size    => $filters->{'limit'} || 5000,
        body    => $q,
    );
    
    my $results = $self->handle->search(%search);
    $results = $results->{'hits'}->{'hits'};
    
    $results = [ map { $_ = $_->{'_source'} } @$results ];

    if(is_ip($args->{'Query'})){
        $results = _ip_results($args->{'Query'},$results);
    } elsif(is_fqdn($args->{'Query'})){
        $results = _fqdn_results($args->{'Query'},$results);
    }
    
    if(defined($args->{'feed'})){
        if($#{$results} >= 0){
            $results = @{$results}[0]->{'Observables'};
        } else {
            $Logger->debug('no results found...');
        }
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
    
    my $timestamp = DateTime->from_epoch(epoch => scalar gettimeofday()); # this is for the record insertion ts
    my $date = $timestamp->ymd('.'); # for the index
    $timestamp = $timestamp->ymd().'T'.$timestamp->hms().'.'.$timestamp->millisecond().'Z';
    
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
    my $err;
   
    $Logger->debug('submitting to index: '.$index);
    
    my $bulk = Search::Elasticsearch::Bulk->new(
        es          => $self->handle,
        index       => $index,
        type        => $type,
        max_count   => $self->max_count,
        max_size    => $self->max_size,
        verbose     => 1,
        refresh     => 1,
    );

    foreach (@$things){
        unless($_->{'group'}){
            $Logger->error('missing group: '.$_->{'observable'});
            return 0;
        }
        $_->{'@timestamp'}  = $timestamp;
        $_->{'@version'}    = 2;
        $_->{'id'}  = hash_create_random();
        $_->{'confidence'} = ($_->{'confidence'}) ? ($_->{'confidence'} + 0.0) : 0; ## work-around cause ES tries to parse anything with quotes around it
        $bulk->index({ 
            id      => $_->{'id'}, 
            source => $_ ,
        });
    }

    my @results = $bulk->flush();
    @results = @{$results[0]->{'items'}};

    @results = map { $_ = $_->{'index'}->{'_id'} } @results;
    
    if($#results == -1){
        $Logger->error('trying to submit something thats too big...');
        $Logger->error(Dumper(@{$things}[0]));
    }  

    return \@results;
}

sub token_list {
    my $self = shift;
    my $args = shift;
    
    my $q;
    if($args->{'Username'}){
        $q = {
            default_field   => 'username',
            query           => $args->{'Username'},
        };
    } elsif($args->{'Token'}) {
        $q = {
            default_field   => 'token',
            query           => $args->{'Token'},
        };
    }
    
    if($q){
        $q = {
    	    query  => {
    	        query_string   => {
    	            query  => $q
    	        }
    	    }
    	}
    } else {
        $q = {
            query => { "match_all" => {} }
        };
    }
	
	my %search = (
	   index   => $self->tokens_index,
	   type    => $self->tokens_type,
	   body    => $q,
    );
    
    my ($res,$err);
    
    try {
        $res = $self->handle->search(%search);
    } catch {
        $err = shift;
    };
    
    if($err){
        return 0 if($err =~ 'Missing');
        $Logger->error($err);
        return 0;
    }

    return 0 if($res->{'hits'}->{'total'} == 0);
    $res = $res->{'hits'}->{'hits'};
    $res = [ map { $_ = $_->{_source} } @$res ];
    
    return $res;
}

sub token_new {
    my $self = shift;
    my $args = shift;
    
    my $token = hash_create_random();
	
	if($args->{'Expires'}){
	    $args->{'Expires'} = normalize_timestamp($args->{'Expires'},undef,1);
	}
	
	$args->{'read'} = 1 unless($args->{'read'} || $args->{'write'});
	
	
	my $prof = {
	   token        => $token,
       username     => $args->{'Username'},
       expires      => $args->{'Expires'},
       
       admin        => $args->{'admin'},
       revoked      => $args->{'revoked'},
       acl          => $args->{'acl'},
       'read'       => $args->{'read'},
       'write'      => $args->{'write'},
       groups       => $args->{'groups'} || ['everyone'],
	};
	
	my $found;
	foreach my $g (@{$prof->{'groups'}}){
	    $found = 1 if($g eq 'everyone');
	}
	push(@{$prof->{'groups'}},'everyone') unless($found);
	
	my $res = $self->handle->index(
	   index   => $self->tokens_index,
	   id      => hash_create_random(),
	   type    => $self->tokens_type,
	   body    => $prof,
	   refresh => 1,
    );
    return $token if($res->{_id});
}

sub token_edit {
    my $self = shift;
    my $args = shift;
    
    my $ids;
    if($args->{'Username'}){
        $ids = $self->_tokenid_by_username($args->{'Username'});
    } else {
        $ids = $self->_tokenid_by_token($args->{'Token'});
    }
    
    return 0 unless($ids);
    
    my $params = {};
    
    $params->{'revoked'}    = 1 if($args->{'revoked'});
    $params->{'read'}       = 1 if($args->{'read'});
    $params->{'write'}      = 1 if($args->{'write'});
    $params->{'acl'}        = $params->{'acl'} if($args->{'acl'});
    $params->{'admin'}      = 1 if($args->{'admin'});
    $params->{'groups'}     = $params->{'groups'} if($args->{'groups'});
    
    if($args->{'Expires'}){
	    $params->{'expires'} = normalize_timestamp($args->{'Expires'},undef,1);
	}
        

    my $bulk = Search::Elasticsearch::Bulk->new(
        es          => $self->handle,
        index       => $self->tokens_index,
        type        => $self->tokens_type,
        refresh     => 1,
    );
    
    foreach my $id (@$ids){
        $Logger->debug('updating: '.$id);
        $bulk->update({
            id      => $id,
            doc     => $params,
        });
    }
    
    my @results = $bulk->flush();
    @results = @{$results[0]->{'items'}};
    @results = map { $_ = $_->{'delete'}->{'_id'} } @results;   
    
    return \@results
    
}
    
sub token_delete {
    my $self = shift;
    my $args = shift;
    
    my $ids;
    if($args->{'Username'}){
        $ids = $self->_tokenid_by_username($args->{'Username'});
    } else {
        $ids = $self->_tokenid_by_token($args->{'Token'});
    }
    
    return 0 unless($ids);
    
    my $bulk = Search::Elasticsearch::Bulk->new(
        es          => $self->handle,
        index       => $self->tokens_index,
        type        => $self->tokens_type,
        refresh     => 1,
    );
    
    foreach my $id (@$ids){
        $Logger->debug('deleting: '.$id);
        $bulk->delete({
            id      => $id,
        });
    }
    
    my @results = $bulk->flush();
    @results = @{$results[0]->{'items'}};
    @results = map { $_ = $_->{'delete'}->{'_id'} } @results;
    
    return \@results
}

sub _tokenid_by {
    my $self    = shift;
    my $q       = shift;
    
    $q = {
	    query  => {
	        query_string   => {
	            query  => $q
	        }
	    }
	};
	
	my %search = (
	   index   => $self->tokens_index,
	   body    => $q,
    );
    
    my $res = $self->handle->search(%search);
    return 0 if($res->{'hits'}->{'total'} == 0);
    
    $res = $res->{'hits'}->{'hits'};
    $res = [ map { $_ = $_->{_id} } @$res ];
    
    return $res;
}

sub _tokenid_by_username {
    my $self        = shift;
    my $username    = shift;

    my $q = { default_field => 'username', query => $username };
    return $self->_tokenid_by($q);
}

sub _tokenid_by_token {
    my $self    = shift;
    my $token   = shift;
    
    my $q = { default_field => 'token', query => $token };
    return $self->_tokenid_by($token);
}

__PACKAGE__->meta()->make_immutable();

1;