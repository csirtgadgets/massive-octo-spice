package CIF::Format::Snort;

use strict;
use warnings;


use Mouse;
use Snort::Rule;

use constant DEFAULT_START_SID  => 50000;

with 'CIF::Format';

has 'start_sid' => (
    is  => 'ro',
    isa => 'Int',
    default => DEFAULT_START_SID(),
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'format'});
    return 1 if($args->{'format'} eq 'snort');
}

sub process {}

__PACKAGE__->meta()->make_immutable();

1;