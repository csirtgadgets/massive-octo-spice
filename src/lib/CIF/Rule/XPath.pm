package CIF::Rule::XPath;

use strict;
use warnings;

use Mouse;

use Carp::Assert;

with 'CIF::Rule';

sub understands {
    my $self = shift;
    my $args = shift;

    return 0 unless($args->{'plugin'});
    return 1 if($args->{'plugin'} eq 'xpath');
}

sub process {
    my $self = shift;
    my $args = shift;

}

__PACKAGE__->meta->make_immutable();

1;
