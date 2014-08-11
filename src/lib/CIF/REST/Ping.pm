package CIF::REST::Ping;
use Mojo::Base 'Mojolicious::Controller';

use warnings;
use strict;

use Time::HiRes qw(gettimeofday);

sub index {
  shift->render( json => { timestamp => [ gettimeofday() ] } );
}

1;
