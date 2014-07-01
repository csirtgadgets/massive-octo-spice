package CIF::Router::REST;

use strict;
use warnings;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->secrets('zomgz....!');
    $self->mode('development');
    $self->sessions->default_expiration(3600*24*7);
    
    my $r = $self->routes;
    $r-namespaces(['CIF::Router::REST::Controller']);
    
    $r->route->('/')->to('ping#index');
    
    $route->('/observables')->via('get')->to('observables#index')->name('observables_show');
    $route->('/observables')->via('post')->to('observables#create')->name('observables_create');
    
    
    
}

1;