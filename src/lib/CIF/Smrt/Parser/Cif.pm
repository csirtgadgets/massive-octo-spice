package CIF::Smrt::Parser::Cif;

use strict;
use warnings;

use Mouse;
use Carp::Assert;
use JSON::XS;
use Try::Tiny;
use Data::Dumper;
use CIF qw/$Logger/;

with 'CIF::Smrt::Parser';

use constant ATTRIBUTES => qw/observable otype tags group tlp application confidence lasttime reporttime firsttime description asn asn_desc altid altid_tlp portlist/;

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} eq 'cif');
}

sub process {
    my $self = shift;
    my $data = shift;
    
    my $defaults = $self->rule->defaults;
    
    return unless($#{$data} > -1);
    
    my $tlp_map = $self->rule->{'tlp_map'} || {};
    
    my @array;
    foreach my $e (@{$data}){
        my $o = {};
        foreach (ATTRIBUTES){
            if(exists($defaults->{$_})){
                $o->{$_} = $defaults->{$_};
            } else {
                if(ref($e->{$_}) eq 'ARRAY'){
                    $o->{$_} = join(',', @{$e->{$_}});
                } else {
                    $o->{$_} = $e->{$_};
                }
            }
        }
        if(keys(%$tlp_map)){
            $o->{'tlp'} = $tlp_map->{$o->{'tlp'}};
            $o->{'altid_tlp'} = $tlp_map->{$o->{'altid_tlp'}};  
        } 
        push(@array,$o);
    }
    
    return(\@array);
}

__PACKAGE__->meta->make_immutable();

1;
