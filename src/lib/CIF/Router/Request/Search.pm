package CIF::Router::Request::Search;

use strict;
use warnings;

use Mouse;
use CIF::Message::Search;
use CIF::ObservableFactory;
use CIF qw/hash_create_static $Logger/;
use Data::Dumper;

with 'CIF::Router::Request';

use constant RE_BADCHARS        => qr/(\/?\.\.+\/?|;|\w+\(|=>)/;
use constant RE_GOODQUERY       => qr/^[a-zA-Z0-9_\.\,\/\-@\:\?=\&\%]+$/;
use constant CONFIDENCE_DEFAULT => 25;
use constant TLP_DEFAULT        => 'amber'; 

sub check {
    my $self    = shift;
    my $q       = shift || return;

    for($q){
        return 0 if(ref($_));
        return 0 if($_ =~ RE_BADCHARS());
        return 0 unless($_ =~ RE_GOODQUERY());
    }
    return 1;
}

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'search');
}

sub process {
    my $self    = shift;
    my $data     = shift;
    
    if($data->{'Query'}){
    	unless($self->check($data->{'Query'})){
    	    $Logger->info('malformed query detected: '.$data->{'Query'});
    	    return -1;
    	}
    } else {
    	return -1 unless ($data->{'Id'} || $data->{'Filters'});
    }
    
    return 0 unless($self->user->{'read'});

    if($data->{'Filters'}->{'group'}){
        return 0 unless($self->in_groups($data->{'Filters'}->{'group'}));
    } else {
        $data->{'Filters'}->{'group'} = $self->user->{'groups'};
    }
    
    if($self->user->{'acl'}){
        return 0 unless($data->{'Filters'}->{'otype'}); # unless it's specified
        return 0 if(ref($data->{'Filters'}->{'otype'})); # unless a string
        return 0 unless($self->user->{'acl'} eq $data->{'Filters'}->{'otype'}); # unless they are equal
    }
    
    my $results = $self->storage->process($data);
    
    if($data->{'Query'} && $data->{'Query'} ne 'all'){
        $self->_log_search($data) unless($data->{'nolog'});
    }
    
    return (-1) unless(ref($results) eq "ARRAY");

    my $resp = CIF::Message::Search->new({
        Results     => $results,
    });
    if($data->{'Query'}){
    	$resp->Query($data->{'Query'});
    } else {
    	$resp->Id($data->{'Id'});
    }
    return $resp;
}

sub _log_search {
    my $self    = shift;
    my $data    = shift;
    
    $Logger->debug('logging search: '.$data->{'Query'});

    my @groups = @{$data->{'Filters'}->{'group'}};
    my $group = 'everyone';
    # get the first group that isn't 'everyone'
    if($#groups > 0){
        foreach my $g (@groups){
            next if $g eq 'everyone';
            $group = $g;
            last;
        }
    }
    
    my $obs = CIF::ObservableFactory->new_plugin({ 
        observable  => $data->{'Query'},
        provider    => $self->{'user'}->{'username'},
        confidence  => CONFIDENCE_DEFAULT(),
        tlp         => TLP_DEFAULT(),
        tags        => ['search'],
        group       => $group,
    });
    
    $obs = $obs->TO_JSON();
    
    my $res = $self->storage->process({ user => $self->user, Observables => [$obs] });
    
    $Logger->debug('search logged');
    return $res;
}

__PACKAGE__->meta()->make_immutable();

1;