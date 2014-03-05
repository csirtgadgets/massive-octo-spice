package CIF::Message::Query;

use strict;
use warnings;


use Mouse;
use CIF::Type;

has 'confidence'    => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    reader  => 'get_confidence',
);

has 'limit' => (
    is      => 'ro',
    isa     => 'Int',
    default => CIF::DEFAULT_QUERY_LIMIT(),
    reader  => 'get_limit',
);

has 'group' => (
    is      => 'ro',
    isa     => 'Str',
    default => CIF::DEFAULT_GROUP(),
    reader  => 'get_group',
);

has 'Query' => (
    is          => 'ro',
    isa         => 'Str',
    reader      => 'get_Query',
    coerce      => 1,
);

has 'Results'   => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_Results',
    writer  => 'set_Results',
); 
   
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'query');
}

sub TO_JSON {
    my $self = shift;

    my $ret = {
        '@confidence'   => $self->get_confidence(),
        '@limit'        => $self->get_limit(),
        '@group'        => $self->get_group(),
        'Query'         => $self->get_Query(),
        'Results'       => $self->get_Results(),
    };
    return $ret;
}

__PACKAGE__->meta()->make_immutable();

1;