package CIF::Router::Request::Token;

use strict;
use warnings;

use Mouse;

with 'CIF::Router::Request';

use CIF::Message::Token;
use CIF qw/$Logger/;
use Data::Dumper;

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} =~ /^token-(list|new|delete|show)$/);
}

sub process {
    my $self    = shift;
    my $msg     = shift;
    
    return 0 unless($self->user->{'admin'});

    my $res;

    for($msg->{'rtype'}){
        if(/-list$/){
            $res = $self->storage_handle->token_list($msg->{'Data'});
            last;   
        }
        if(/-new$/){
            $res = $self->storage_handle->token_new($msg->{'Data'});
            return 0 unless($res);
            last;
        }
        if(/-delete$/){
            $res = $self->storage_handle->token_delete($msg->{'Data'});
            last;
        }
    }
   

    $res = 'CIF::Message::Token'->new({
        Results => $res,
    });

    return $res;
    
}

__PACKAGE__->meta()->make_immutable();

1;