package CIF::Message::Search;

use strict;
use warnings;

use Mouse;

has [qw/Id Query Results Filters feed/] => (
    is  => 'ro',
);

has [qw/feed nolog/] => (
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

    my $ret = {
        'Query'         => $self->get_Query(),
        'Id'			=> $self->get_Id(),
        'Results'       => $self->get_Results(),
        'Filters'       => $self->get_Filters(),
        'feed'          => $self->feed,
        'nolog'         => $self->nolog,
    };
    return $ret;
}

__PACKAGE__->meta()->make_immutable();

1;
