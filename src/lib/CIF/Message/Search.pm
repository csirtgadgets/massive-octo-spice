package CIF::Message::Search;

use strict;
use warnings;

use Mouse;

has 'Id'	=> (
	is     => 'rw',
	reader => 'get_Id',
	writer => 'set_Id',
);

has 'Query' => (
    is          => 'rw',
    reader      => 'get_Query',
    writer      => 'set_Query',
);

has 'Results'   => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_Results',
    writer  => 'set_Results',
);

has 'Filters' => (
    is      => 'ro',
    reader  => 'get_Filters',
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
    };
    return $ret;
}

__PACKAGE__->meta()->make_immutable();

1;
