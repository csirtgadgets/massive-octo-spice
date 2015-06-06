package CIF::Smrt::Parser::Json;

use strict;
use warnings;

use Mouse;
use Carp::Assert;
use JSON::XS;
use Try::Tiny;

with 'CIF::Smrt::Parser';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} eq 'json');
}

sub process {
    my $self = shift;
    my $data = shift;
    
    my $defaults = $self->rule->defaults;
    
    my @map = @{ $defaults->{'map'} };
    assert(@map,'missing map param'); 
    
    my @values = @{ $defaults->{'values'} };
    assert(@values,'missing values param');  
    
    # in case they don't send us a json encoded array
    if($data =~ /^{/ && $data =~ /}$/){
        $data = '['.$data.']';
    }
    
    my @feed = @{JSON::XS->new->decode($data)};
    
    return unless($#feed > -1);
    
    my ($start,$end) = (0,($#feed-1));
    $end = $defaults->{'limit'} if($defaults->{'limit'});

    my @array;
    my ($x,$y,$z);

    for (my $i = 0; $i <= $end; $i++){
        $x = $feed[$i];
        foreach (0 ... $#map){
            $z->{$values[$_]} = $x->{$map[$_]};
        }
        push(@array,$z);
        ($x,$y,$z) = (undef,undef);
    }
    return(\@array);
}

__PACKAGE__->meta->make_immutable();

1;
