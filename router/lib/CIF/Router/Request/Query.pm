package CIF::Router::Request::Query;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use CIF::Message::Query;

with 'CIF::Router::Request';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'@rtype'});
    return 1 if($args->{'@rtype'} eq 'query');
}

sub process {
    my $self    = shift;
    my $msg     = shift->{'Data'} || return -1;

    my $results = $self->get_storage_handle()->process({
        Query       => $msg->{'Query'},
        confidence  => $msg->{'@confidence'},
        limit       => $msg->{'@limit'},
        group       => $msg->{'@group'},
    });
    $results = [ $results ] unless(ref($results) eq 'ARRAY');

    my $resp = CIF::Message::Query->new({
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