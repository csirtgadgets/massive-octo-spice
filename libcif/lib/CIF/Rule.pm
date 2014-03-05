package CIF::Rule;

use strict;
use warnings;


use Mouse::Role;

use constant RE_COMMENTS => qr/^(#|;)/;

has 'not_before'    => (
    is      => 'ro',
    isa     => 'CIF::Type::DateTimeInt',
    coerce  => 1,
    reader  => 'get_not_before',
);

has [qw(fetcher parser)] => (
    is      => 'ro',
);

has 'defaults' => (
    is      => 'rw',
    isa     => 'HashRef',
    #slurpy  => 1,
    reader  => 'get_defaults',
    writer  => 'set_defaults',
);

has 'comments'  => (
    is      => 'ro',
    isa     => 'RegexpRef',
    default => sub { RE_COMMENTS() },
    reader  => 'get_comments',
);

has 'remote'    => (
    is      => 'ro',
    reader  => 'get_remote',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;
    
    $args->{'defaults'} = {%$args};
    delete($args->{'defaults'}->{'remote'});
    
    return $self->$orig($args);  
};

requires qw(understands process);

1;