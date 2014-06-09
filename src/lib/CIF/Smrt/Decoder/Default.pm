package CIF::Smrt::Decoder::Default;

use strict;
use warnings;

use Mouse;

with 'CIF::Smrt::Decoder';

# this is here since pluginfinder dies's stupidly
sub understands {
    my $self = shift;
    my $args = shift;
    
    return 1 if($args->{'type'} eq 'application/octet-stream');
}

sub process {
    my $self = shift;
    my $args = shift;
    
    return $args->{'data'};
}

__PACKAGE__->meta()->make_immutable();

1;