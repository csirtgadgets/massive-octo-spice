package CIF::Router::Request::Submission;

use strict;
use warnings;

use Mouse;
use CIF::Message::Submission;

with 'CIF::Router::Request';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'submission');
}

sub process {
    my $self    = shift;
    my $data    = shift || return -1;
    
    return 0 unless($self->user->{'write'});
    
    my $results = $self->storage->process($data);
    
    return 0 unless($results);
    
    $results = [ $results ] unless(ref($results) eq 'ARRAY');

    my $resp = CIF::Message::Submission->new({
        Results     => $results,
    });
    return $resp;
}

__PACKAGE__->meta()->make_immutable();

1;
