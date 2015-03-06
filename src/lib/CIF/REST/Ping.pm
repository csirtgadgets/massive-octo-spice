package CIF::REST::Ping;
use Mojo::Base 'Mojolicious::Controller';

use warnings;
use strict;

use Time::HiRes qw(gettimeofday);

sub index { 
    my $self  = shift;
    
    my $write = scalar $self->param('write') || 0;
    my $res;
    
    if($write){
        $res = $self->cli->ping_write({
            token      => $self->token
        });
    } else {
        $res = $self->cli->ping({
            token      => $self->token
        });
    }

    if($res > 0){
        $self->render( json => { timestamp => [ gettimeofday() ] } );
    } elsif (defined($res) && $res == 0) {
         $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
    } else {
        $self->render(json   => { 'message' => 'unknown failure' }, status => 500 );
    }
}

1;
