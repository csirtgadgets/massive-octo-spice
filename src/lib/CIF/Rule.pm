package CIF::Rule;

use strict;
use warnings;

use Mouse::Role;
use DateTime;
use CIF::MetaFactory;

use constant RE_COMMENTS => qr/^([#|;]+)/;

has 'not_before'    => (
    is          => 'ro',
    isa         => 'CIF::Type::DateTimeInt',
    coerce      => 1,
    reader      => 'get_not_before',
    default     => sub { DateTime->today()->epoch() },
);

has [qw(fetcher parser)] => (
    is      => 'ro',
);

has 'defaults' => (
    is      => 'rw',
    isa     => 'HashRef',
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

has '_now' => (
    is          => 'ro', 
    isa         => 'CIF::Type::DateTimeInt',
    reader      => 'get__now',
    default     => sub { time() },
);

has 'skip_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
    reader  => 'get_skip_comments',
);

has 'meta'  => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_meta',
);

has '_meta'  => (
    is      => 'ro',
    isa     => 'ArrayRef',
    reader  => 'get__meta',
    default => sub { [ CIF::MetaFactory::_meta_plugins() ] },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    $args->{'defaults'} = {%$args};
    delete($args->{'defaults'}->{'remote'});    
    return $self->$orig($args);  
};

sub process_meta {
    my $self = shift;
    my $args = shift;
    
    return unless($self->get_meta());
    
    foreach my $p (@{$self->get__meta()}){
        next unless($p->understands($args->{'data'}));
        $p = $p->new();
        $p->process($args->{'data'});
    }
}

requires qw(understands process);

1;
