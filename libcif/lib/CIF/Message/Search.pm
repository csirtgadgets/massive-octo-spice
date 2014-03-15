package CIF::Message::Search;

use strict;
use warnings;

use Mouse;
use CIF::Type;

has 'confidence'    => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_confidence',
);

has 'limit' => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_limit',
);

has 'group' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_group',
    coerce  => 1,
);

has 'Tags'  => (
    is      => 'ro',
    isa     => 'ArrayRef',
    reader  => 'get_tags',
    coerce  => 1,
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
    return 1 if($args->{'rtype'} eq 'search');
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;
    
    $args->{'group'}        = '' unless($args->{'group'});
    $args->{'Tags'}         = [] unless($args->{'Tags'});
    $args->{'confidence'}   = 0 unless(defined($args->{'confidence'}));
    $args->{'limit'}        = 500 unless(defined($args->{'limit'}));
    
    
    return $self->$orig($args);
};

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
