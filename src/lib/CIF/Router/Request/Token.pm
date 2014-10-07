package CIF::Router::Request::Token;

use strict;
use warnings;

use Mouse;

with 'CIF::Router::Request';

use CIF::Message::Token;
use CIF qw/$Logger/;

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} =~ /^token-/);
}

sub process {
    my $self    = shift;
    my $msg     = shift;
    
    my $res = $self->auth->process($msg);
    
    return (-1) unless($res);

    $res = 'CIF::Message::Token'->new({
        Token   => $res->{'token'},
    });
    return $res;
    
}

__PACKAGE__->meta()->make_immutable();

1;