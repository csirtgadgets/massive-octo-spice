package CIF::Router::Request::Submission;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use Time::HiRes qw(tv_interval);
use CIF::Message::Submission;

with 'CIF::Router::Request';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'@rtype'});
    return 1 if($args->{'@rtype'} eq 'submission');
}

sub process {
    my $self    = shift;
    my $msg     = shift->{'Data'} || return -1;

    my $results = $self->get_storage_handle()->process({
        Observables => $msg->{'Observables'},
    });
    $results = [ $results ] unless(ref($results) eq 'ARRAY');

    my $resp = CIF::Message::Submission->new({
        Results     => $results,
    });
    
    return $resp;
}

__PACKAGE__->meta()->make_immutable();

1;