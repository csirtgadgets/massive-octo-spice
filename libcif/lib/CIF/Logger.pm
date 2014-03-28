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

sub _build_logger {
    my $self = shift;
    my $args = shift;
    
    my $layout = "[%p][%d{yyyy-MM-dd'T'HH:mm:ss}Z]: %m%n";
    $layout = "[%p][%d{yyyy-MM-dd'T'HH:mm:ss}Z][%F:%L]: %m%n" if($self->level() eq 'DEBUG');
    
    Log::Log4perl->easy_init({
        level       => $self->level(),
        category    => $self->category(),
        layout      => $layout,
    });
    return Log::Log4perl->get_logger($self->category());
}

__PACKAGE__->meta()->make_immutable();

1;