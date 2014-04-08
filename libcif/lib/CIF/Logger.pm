package CIF::Logger;

use strict;
use warnings;

use Mouse;
use Log::Log4perl;
use Log::Log4perl::Level;

use constant LAYOUT_DEFAULT => "[%d{yyyy-MM-dd'T'HH:mm:ss,SSS}Z][%p]: %m%n";
use constant LAYOUT_DEBUG   => "[%d{yyyy-MM-dd'T'HH:mm:ss,SSS}Z][%p][%F:%L]: %m%n"; 

has 'level' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ERROR',
    reader  => 'get_level',
);

has 'layout'    => (
    is          => 'ro',
    isa         => 'Str',
    reader      => 'get_layout',
    builder     => '_build_layout',
);

has 'category'  => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_category',
    default => 'CIF.Logger',
);

has 'name'  => (
    is      => 'ro',
    isa     => 'Str',
    default => 'libcif',
    reader  => 'get_name',
);

has 'logger' => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    builder     => '_build_logger',
    required    => 1,
    reader      => 'get_logger',
);

sub _build_layout {
    my $self = shift;
    
    return LAYOUT_DEBUG() if($self->get_level() eq 'DEBUG');
    return LAYOUT_DEFAULT()
}

sub _build_logger {
    my $self = shift;
    
    Log::Log4perl->easy_init({
        level       => $self->get_level(),
        layout      => $self->get_layout(),
        name        => $self->get_name(),
        category    => $self->get_category(),
    });
    return Log::Log4perl->get_logger($self->get_category());
}

__PACKAGE__->meta()->make_immutable();

1;