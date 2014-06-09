package CIF::Encoder::Json;

use warnings;
use strict;

use Mouse;
use JSON::XS;

with 'CIF::Encoder';

sub understands { 
    my $self = shift;
    my $args = shift;
    
    return 1 unless($args->{'encoder'});
    return 1 if($args->{'encoder'} eq 'json');
    return 1 if($args->{'encoder'} eq 'default');
    return 0;    
}

sub encode {
    my $self = shift;
    my $args = shift;

    if($args->{'encoder_pretty'}){
        return JSON::XS->new->pretty->convert_blessed(1)->encode($args->{'data'});
    } else {
        return JSON::XS->new->convert_blessed(1)->encode($args->{'data'});
    }
}

sub decode {
    my $self = shift;
    my $args = shift;

    return unless($args->{'data'});
    return JSON::XS->new->decode($args->{'data'});
}

__PACKAGE__->meta->make_immutable();

1;