package CIF::Smrt::Handler::Irc;

use warnings;
use strict;

use Mouse;

with 'CIF::Smrt::Handler';

# http://search.cpan.org/~elmex/AnyEvent-IRC-0.97/lib/AnyEvent/IRC.pm
# http://search.cpan.org/~hinrik/Bot-BasicBot-0.89/lib/Bot/BasicBot.pm

sub understands {
    my $self = shift;
    my $args = shift;

    return 0 unless($args->{'handler'});
    return 1 if($args->{'handler'} eq 'irc');
    return 0;
}

sub fetch {}

sub process {}

__PACKAGE__->meta->make_immutable();

1;