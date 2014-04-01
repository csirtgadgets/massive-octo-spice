package CIF::Logger;

use strict;
use warnings;

use Mouse;
use Log::Log4perl;
use Log::Log4perl::Level;

has 'logger' => (
    is          => 'ro',
    isa         => 'Log::Log4perl::Logger',
    lazy_build  => 1,
    reader      => 'get_logger',
);

has 'level' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ERROR',
);

has 'category'  => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'name'  => (
    is      => 'ro',
    isa     => 'Str',
    default => 'libcif',
);

has [qw(errors_to errors_from errors_subj)] => (
    is      => 'ro',
    isa     => 'Str',
);

sub _build_logger {
    my $self = shift;
    my $args = shift;
    
    my $layout = "[%d{yyyy-MM-dd'T'HH:mm:ss,SSS}Z][%p]: %m%n";
    $layout = "[%d{yyyy-MM-dd'T'HH:mm:ss,SSS}Z][%p][%F:%L]: %m%n" if($self->level() eq 'DEBUG');
    
    Log::Log4perl->easy_init({
        level       => $self->level(),
        category    => $self->category(),
        layout      => $layout,
        name        => $self->name(),
    });
    return Log::Log4perl->get_logger($self->category());
}

__PACKAGE__->meta()->make_immutable();

1;