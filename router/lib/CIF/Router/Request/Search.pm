package CIF::Router::Request::Search;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use CIF::Message::Search;

with 'CIF::Router::Request';

use constant RE_BADCHARS    => qr/(\/?\.\.+\/?|;|\w+\(|=>)/;
use constant RE_GOODQUERY   => qr/^[a-zA-Z0-9_\.\,\/\-@]+$/;

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

    return unless($args->{'@rtype'});
    return 1 if($args->{'@rtype'} eq 'search');
}

sub process {
    my $self    = shift;
    my $msg     = shift->{'Data'} || return -1;

    return (-1) unless($self->check($msg->{'Query'}));
    
    my $results = $self->get_storage_handle()->process({
        Query       => $msg->{'Query'},
        confidence  => $msg->{'@confidence'},
        limit       => $msg->{'@limit'},
        group       => $msg->{'@group'},
    });
    
    return (-1) unless(ref($results) eq "ARRAY");

    my $resp = CIF::Message::Search->new({
        limit       => $msg->{'@limit'},
        confidence  => $msg->{'@confidence'},
        group       => $msg->{'@group'},
        Query       => $msg->{'Query'},
        Results     => $results,
    });
    return $resp;
}

__PACKAGE__->meta()->make_immutable();

1;