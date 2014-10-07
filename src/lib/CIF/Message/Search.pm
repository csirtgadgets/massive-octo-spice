package CIF::Message::Search;

use strict;
use warnings;

use Mouse;

has [qw/Id Query Results Filters feed/] => (
    is  => 'ro',
);
	   
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'search');
}

sub TO_JSON {
    my $self = shift;

    return {
        'Query'         => $self->Query,
        'Id'			=> $self->Id,
        'Results'       => $self->Results,
        'Filters'       => $self->Filters,
        'feed'          => $self->feed,
    };
}

__PACKAGE__->meta()->make_immutable();

1;
