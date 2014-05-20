package CIF::Observable::Uri;

use strict;
use warnings;


use Mouse;
use CIF qw/is_url/;

with 'CIF::Observable';

has '+otype' => (
    default => 'url',
);

has '+observable'    => (
    isa     => 'CIF::Type::Uri',
);

sub process {}
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'observable'});
    return unless(is_url($args->{'observable'}));
    return 1;
}



__PACKAGE__->meta()->make_immutable();

1;