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
    MAX_SIZE            => 0,
    MAX_COUNT           => 0,
    OBSERVABLES         => 'cif.observables',
    OBSERVABLES_TYPE    => 'observables',
    LIMIT               => 225000, #225,000 tuned for a ElasticSearch build with 16GB of ram
    SOFT_LIMIT          => 50000,
    TOKENS_INDEX        => 'cif.tokens',
    TOKENS_TYPE         => 'tokens',
    TIMEOUT             => 300,
    INDEX_PARTITION     => 'month',
    FEED_DAYS           => 90,
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

has 'index_partition' => (
    is => 'ro',
    default => sub { INDEX_PARTITION }
);

sub _build_handle {
    my $self = shift;
    my $args = shift;

    
 
    $self->handle(
        Search::Elasticsearch->new(
            nodes               => $self->nodes,
            max_content_length  => $self->max_size,
            request_timeout     => TIMEOUT,
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
    $Logger->debug('storage node: ' . join(',', @{$self->nodes}));
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
            $Logger->debug('token is expired: '.$token);
            return 0;
        }
    }
    
    $Logger->debug(Dumper($res));
    return $res;
}

sub process {
    my $self = shift;
    my $args = shift;
   
    unless($self->check_handle()){
        $Logger->warn('storage handle check failed...');
        return -1;
    } else {
        $Logger->debug('storage handle OK');
    }
    
    my $ret;
    if($args->{'Query'} || $args->{'Id'} || $args->{'Filters'}){
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
    
    my $groups = $args->{'group'};
    $groups = [$groups] unless(ref($groups) && ref($groups) eq 'ARRAY');
    
    my ($q,$terms,$ranges,$prefix,$regexp);
    
    $Logger->debug(Dumper($args));
    my $filters = $args->{'Filters'};
       
    if($args->{'Id'}){
    	$terms->{'id'} = [$args->{'Id'}];
    } elsif($args->{'Query'}) {
    	if($args->{'Query'} ne 'all'){
    		if(my $otype = is_ip($args->{'Query'})){
    		    if ($otype eq 'ipv4') {
                    my @array = split(/\./,$args->{'Query'});
        		    $prefix->{'observable'} = $array[0].'.'.$array[1].'.';
        		    $terms->{'otype'} =  ['ipv4'];
    		    } else {
    		        # v6
    		        my @array = split(/\:/,$args->{'Query'});
        		    $prefix->{'observable'} = $array[0].':'.$array[1].':';
    		        $terms->{'otype'} = ['ipv6'];
    		    }
    		} else {
    		    $terms->{'observable'} = [$args->{'Query'}];
    		}
    	}
    } elsif(!$filters->{'reporttime'} && !$filters->{'reporttimeend'}) {
        # if we're querying for something specific and don't specify a reporttime
        # cap default otype queries (feed queries) to DEFAULT_FEED_DAYS to improve search performance
        my $dt = DateTime->from_epoch(epoch => time());
        $filters->{'reporttime'} = DateTime->now()->subtract(days => FEED_DAYS);
        $filters->{'reporttime'} = $filters->{'reporttime'}->ymd().'T'.$filters->{'reporttime'}->hms().'Z';
        $filters->{'reporttimeend'} = $dt->ymd().'T'.$dt->hms().'Z';
	}
    
    $Logger->debug(Dumper($filters));
    
    if($filters->{'otype'}){
    	$terms->{'otype'} = [$filters->{'otype'}];
	}
	my $missing;
    
    if($filters->{'confidence'}){
    	$ranges->{'confidence'}->{'gte'} = $filters->{'confidence'};
    }
    
    if($filters->{'firsttime'}){
    	$ranges->{'firsttime'}->{'gte'} = $filters->{'firsttime'};
    }
    
    if($filters->{'lasttime'}){
    	$ranges->{'lasttime'}->{'lte'} = $filters->{'lasttime'};
    }
    
    if($filters->{'reporttime'}){
    	$ranges->{'reporttime'}->{'gte'} = $filters->{'reporttime'};
    }
    
    if($filters->{'reporttimeend'}){
        $ranges->{'reporttime'}->{'lte'} = $filters->{'reporttimeend'};
    }
    
    if($filters->{'tags'}){
    	$filters->{'tags'} = [$filters->{'tags'}] unless(ref($filters->{'tags'}) eq 'ARRAY');
    	$terms->{'tags'} = $filters->{'tags'};
    }
    
    if($filters->{'description'}){
        unless(ref($filters->{'description'}) eq 'ARRAY'){
            $filters->{'description'} = [ split(',',$filters->{'description'}) ];
        }
        $terms->{'description'} = $filters->{'description'}
    }
    
    if($filters->{'application'}){
    	$filters->{'application'} = [$filters->{'application'}] unless(ref($filters->{'application'}) eq 'ARRAY');
    	$terms->{'application'} = $filters->{'application'};
    }
    
    if($filters->{'asn'}){
        unless(ref($filters->{'asn'}) eq 'ARRAY'){
            $filters->{'asn'} = [ split(',',$filters->{'asn'}) ];
        }
        $terms->{'asn'} = $filters->{'asn'}
    }
    
    if($filters->{'cc'}){
        unless(ref($filters->{'cc'}) eq 'ARRAY'){
            $filters->{'cc'} = [ split(',',lc($filters->{'cc'})) ];
        }
        $terms->{'cc'} = $filters->{'cc'}
    }
    
    if($filters->{'otype'}){
        unless(ref($filters->{'otype'}) eq 'ARRAY'){
            $filters->{'otype'} = [ split(',',$filters->{'otype'}) ];
        }
        $terms->{'otype'} = $filters->{'otype'}
    }
    
    if($filters->{'provider'}){
        unless(ref($filters->{'provider'} eq 'ARRAY')){
            $filters->{'provider'} = [ split(',', $filters->{'provider'}) ]
        }
        $terms->{'provider'} = $filters->{'provider'}
    }
    
    if($filters->{'tlp'}){
        $filters->{'tlp'} = [$filters->{'tlp'}] unless(ref($filters->{'tlp'}));
        $terms->{'tlp'} = $filters->{'tlp'}
    }
    
    if($filters->{'rdata'}){
         unless(ref($filters->{'rdata'})){
             $filters->{'rdata'} = [ $filters->{'rdata'} ];
         }
        $terms->{'rdata'} = $filters->{'rdata'};
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
            } elsif($_ eq 'group') {
                my @or;
                foreach my $e (@{$terms->{$_}}){
                	push(@or, { term => { $_ => [$e] } } );
                }
                push(@and, { 'or' => \@or });
            } elsif($_ eq 'asn') {
                my @or;
                foreach my $e (@{$terms->{$_}}){
                	push(@or, { term => { $_ => [$e] } } );
                }
                push(@and, { 'or' => \@or });
            } elsif($_ eq 'provider'){
                my @or;
                foreach my $e (@{$terms->{$_}}){
                	push(@or, { term => { $_ => [$e] } } );
                }
                push(@and, { 'or' => \@or });
            } elsif($_ eq 'cc'){
                my @or;
                foreach my $e (@{$terms->{$_}}){
                	push(@or, { term => { $_ => [$e] } } );
                }
                push(@and, { 'or' => \@or });
            } elsif($_ eq 'otype'){
                my @or;
                foreach my $e (@{$terms->{$_}}){
                	push(@or, { term => { $_ => [$e] } } );
                }
                push(@and, { 'or' => \@or });
            } elsif($_ eq 'description'){
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
	
	if($prefix){
        foreach (keys %$prefix){
                push(@and, { prefix => { $_ => $prefix->{$_} } } );
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
	        	},
	        	query => {
	        	    'match_all' => {},
	        	},
	        },
	    },
	    'sort' =>  [
            { 'reporttime' => { 'order' => 'desc'}},
        ],
	};
	
	if($Logger->is_debug()){
	    my $j = JSON->new();
        $Logger->debug($j->pretty->encode($q));
	}
	
    my $index = $self->observables_index();
    
    $index .= '-*';
    
    $Logger->debug('searching index: '.$index);
    
    my %search = (
        index   => $index,
        size    => $filters->{'limit'} || SOFT_LIMIT,
        body    => $q,
        timeout => 30000000 # 300s
    );
    
    # work-around https://github.com/csirtgadgets/massive-octo-spice/issues/257#issuecomment-118855811
    # cleaner fix in v3
    if(is_ip($args->{'Query'})){
        %search = (
            index   => $index,
            size    => LIMIT,
            body    => $q,
        );
    }
    
    $Logger->debug(Dumper($filters));
    
    my $results = $self->handle->search(%search);
    $results = $results->{'hits'}->{'hits'};
    
    $results = [ map { $_ = $_->{'_source'} } @$results ];

    if(is_ip($args->{'Query'})){
        $results = _ip_results($args->{'Query'},$results);
    } elsif(is_fqdn($args->{'Query'})){
        $results = _fqdn_results($args->{'Query'},$results);
    } elsif($args->{'Filters'}->{'rdata'} && is_fqdn($args->{'Filters'}->{'rdata'})) {
        $results = _fqdn_results($args->{'Filters'}->{'rdata'},$results);
    }
    
    if($filters->{'limit'} && $filters->{'limit'} < $#{$results}){
        $#{$results} = ($filters->{'limit'} - 1);
    }
    $Logger->debug($#{$results});    
    
    $Logger->debug('returning..');
    return $results;
}

sub _ip_results {
    my $query = shift;
    my $results = shift;
    
    my $type = is_ip($query);
    
    my $pt = Net::Patricia->new();
    if ($type eq 'ipv6'){
        $pt = new Net::Patricia AF_INET6;
    }

    $pt->add_string($query);
    my @ret; my $pt2;
    foreach (@$results){
        if(is_ip($_->{'observable'}) ne $type){
            $Logger->error('skipping: '.$_->{'observable'});
            next;
        }
        #$Logger->debug($_->{'observable'});
        if($pt->match_string($_->{'observable'})){
            push(@ret,$_);
        } else {
            $pt2 = Net::Patricia->new();
            if ($type eq 'ipv6'){
                $pt2 = new Net::Patricia AF_INET6;
            }
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
    
    my $timestamp = $args->{'timestamp'} || DateTime->from_epoch(epoch => scalar gettimeofday()); # this is for the record insertion ts
    my $date = $timestamp->ymd('.'); # for the index
    if($self->index_partition eq 'month'){
        $date = $timestamp->strftime("%Y.%m");
    }
    my $reportstamp = $timestamp->ymd().'T'.$timestamp->hms().'Z';
    $timestamp = $timestamp->ymd().'T'.$timestamp->hms().'.'.$timestamp->millisecond().'Z';
    
    my ($things,$index,$type);
    
    if($args->{'Observables'}){
        $things = $args->{'Observables'};
        $index = $self->observables_index();
        $type = 'observables';
    }
    
    $index = $index.'-'.$date;
    
    my $id;
    my $err;
   
    $Logger->debug('submitting to index: '.$index);
    
    my $bulk = $self->handle->bulk_helper(
        index       => $index,
        type        => $type,
        verbose     => 1,
        refresh     => 1,
        max_count   => $self->max_count,
        max_size    => $self->max_size,
        on_error    => sub {
            my ($a,$r,$i) = @_;
            $Logger->debug(Dumper($r));
            $Logger->error($r->{'error'});
        },
    );
    
    my $usergroups = {};
    foreach my $g (@{$args->{'user'}->{'groups'}}){
        $usergroups->{$g} = 1;
    }
    
    # we may want to change this so we're flushing every X count or X size???
    # http://search.cpan.org/~drtech/Search-Elasticsearch-1.16/lib/Search/Elasticsearch/Bulk.pm
    # https://github.com/csirtgadgets/massive-octo-spice/issues/117
    foreach (@$things){
        unless($_->{'group'}){
            $Logger->error('missing group: '.$_->{'observable'});
            return 0;
        }
        $_->{'group'} = [ $_->{'group'} ] unless(ref($_->{'group'}) eq 'ARRAY'); 
        foreach my $g (@{$_->{'group'}}){
            unless($usergroups->{$g}){
                $Logger->debug(Dumper($args));
                $Logger->error($args->{'user'}->{'username'} . ' unauthorized to post to group: '.$g);
                return 0;
            }
        }
        
        $_->{'provider'} = $args->{'username'} unless($_->{'provider'});

        $_->{'@timestamp'}  = $timestamp;
        $_->{'@version'}    = 2;
        $_->{'id'}  = hash_create_random();
        $_->{'confidence'} = ($_->{'confidence'}) ? ($_->{'confidence'} + 0.0) : 0; ## work-around cause ES tries to parse anything with quotes around it
        $_->{'lasttime'} = $reportstamp unless($_->{'lasttime'});
        $_->{'reporttime'} = $reportstamp unless($_->{'reporttime'});
        $_->{'firsttime'} = $reportstamp unless($_->{'firsttime'});
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
        #$Logger->error(Dumper(@{$things}[0]));
        #warn Dumper($bulk);
    }  

    return \@results;
}

sub token_list {
    my $self = shift;
    my $args = shift;
    
    my $q;
    if($args->{'Username'}){
        $q = {
            default_field           => 'username',
            query                   => $args->{'Username'},
            minimum_should_match    => 100
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
	   size    => 5000,
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
    
    my $token = $args->{'token'} || hash_create_random();

    if($args->{'Expires'}){
        $args->{'Expires'} = normalize_timestamp($args->{'Expires'},undef,1);
    }

    $args->{'read'} = 1 unless($args->{'read'} || $args->{'write'});

    my $found;

    foreach my $g (@{$args->{'groups'}}){
        $found = 1 if($g eq 'everyone');
    }

    unless($args->{'no-everyone'}) {
        push(@{$args->{'groups'}},'everyone') unless($found);
    }
    
    my $prof = {
       token        => $token,
       username     => $args->{'Username'},
       expires      => $args->{'Expires'},
       description  => $args->{'description'},

       admin        => $args->{'admin'},
       revoked      => $args->{'revoked'},
       acl          => $args->{'acl'},
       'read'       => $args->{'read'},
       'write'      => $args->{'write'},
       groups       => $args->{'groups'},
   };

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
    
    if(defined($args->{'read'})){
        $params->{'read'} = $args->{'read'};
    }
    
    if(defined($args->{'write'})){
        $params->{'write'} = $args->{'write'};
    }
    
    if(defined($args->{'revoked'})){
        $params->{'revoked'} = $args->{'revoked'};
    }
    
    if(defined($args->{'admin'})){
        $params->{'admin'} = $args->{'admin'};
    }
    
    
    $params->{'acl'}        = $params->{'acl'} if($args->{'acl'});
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
        size        => 10000,
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
	            query                  => $q,
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

    my $q = { 
        default_field           => 'username',
        query                   => $username,
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
        minimum_should_match    => 100
    };
    
    return $self->_tokenid_by($q);
}

sub _tokenid_by_token {
    my $self    = shift;
    my $token   = shift;
    
    my $q = { 
        default_field           => 'token', 
        query                   => $token,
        minimum_should_match    => 100
    };
    return $self->_tokenid_by($token);
}

__PACKAGE__->meta()->make_immutable();

1;
