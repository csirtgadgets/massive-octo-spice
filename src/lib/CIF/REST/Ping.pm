package CIF::REST::Ping;
use Mojo::Base 'Mojolicious::Controller';

use warnings;
use strict;

use Time::HiRes qw(gettimeofday);

sub index { 
    my $self  = shift;
    
    my $res = $self->cli->ping({
        token      => scalar $self->param('token'),
    });

    if($res){
        $self->render( json => { timestamp => [ gettimeofday() ] } );
    } elsif (defined($res) && $res == 0) {
         $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
    } else {
        $self->render(json   => { 'message' => 'unknown failure' }, status => 500 );
    }
}

1;
