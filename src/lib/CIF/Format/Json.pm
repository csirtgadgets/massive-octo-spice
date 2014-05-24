package CIF::Format::Json;

use strict;
use warnings;

use Mouse;
use JSON::XS;

with 'CIF::Format';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'format'});
    return 1 if($args->{'format'} eq 'json');
}

sub process {
    my $self = shift;
    my $data = shift;
    return JSON::XS->new->pretty->convert_blessed(1)->encode($data);
}

__PACKAGE__->meta()->make_immutable();

1;
