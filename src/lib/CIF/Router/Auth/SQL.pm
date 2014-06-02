package CIF::Router::Auth::SQL;

use strict;
use warnings;

use Mouse;

with 'CIF::Router::Auth';

has 'handle' => (
    is      => 'ro',
    reader  => 'get_handle',
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'plugin'});
    return 1 if($args->{'plugin'} eq 'sql');
}

sub process {
    my $self = shift;
    my $args = shift;
    
    
}

__PACKAGE__->meta()->make_immutable();

1;