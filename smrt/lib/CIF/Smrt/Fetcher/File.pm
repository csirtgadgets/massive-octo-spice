package CIF::Smrt::Fetcher::File;

use strict;
use warnings;

use Mouse;
use File::Type;
use URI::file;
use IO::File;

use constant RE_FILE    => qr/^(file:\/\/|\.?\/?[\w|\/]+)/;

with 'CIF::Smrt::Fetcher';

sub understands {
    my $self = shift;
    my $args = shift;

    return 1 if($args->{'rule'}->get_remote() =~ RE_FILE());
    return 0;
}

sub process {
    my $self = shift;
    my $args = shift;

    return $self->process_file({ file => $self->get_rule()->get_remote() });
}

__PACKAGE__->meta->make_immutable();

1;