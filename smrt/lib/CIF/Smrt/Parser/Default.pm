package CIF::Smrt::Parser::Default;

use 5.011;
use strict;
use warnings;
use namespace::autoclean;

use Mouse;

use Carp::Assert;

with 'CIF::Smrt::Parser';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 1 unless($args->{'rule'}->{'parser'});

    given($args->{'rule'}->{'parser'}){
        return 1 when(/^(delim|csv|pipe|default)/);
    }
}


sub process {
    my $self = shift;
    my $args = shift;

    my $cols = $self->get_rule()->get_values();
    assert($cols,'missing values param');
    
    my @array;
    
    my $pattern = $self->get_rule()->get_pattern();
    $pattern = qr/$pattern/;
    unless(defined($pattern)){
        for($self->get_rule()->get_parser()){
            $pattern = ',' if(/^csv$/);
            $pattern = qr/\||\s+\|\s+/ if(/^pipe$/);
        }
    }
    
    my ($start,$end) = (0,$#{$args->{'content'}});
    $end = $self->get_rule()->get_limit() if($self->get_rule()->get_limit());
    
    if($self->get_rule()->get_skip_first()){
    	$start = ($start + 1);
    	$end = ($end+1);
    }

    my ($x,@y);
    for (my $i = $start; $i < $end; $i++){
        $x = @{$args->{'content'}}[$i];
        next if($x =~ $self->get_rule->get_comments());
        next unless($x =~ $pattern);
        
        if(ref($pattern) eq 'Regexp'){
        	$x =~ $pattern;
        	push(@y,($1,$2));
        } else {
            @y = split($pattern,$x);
        }
        
        # if we're dealing with csv, strip the ""'s if they exist
        s/"//g foreach(@y);
        my $z;
        foreach (0 ... $#{$cols}){
            next if($cols->[$_] eq 'null');
            $z->{$cols->[$_]} = $y[$_];
        }
        
        if($self->get_rule()->get_store_content()){
                $z->{'additionaldata'} = [$x];
        }
        push(@array,$z);
    }

    return(\@array);
}

__PACKAGE__->meta->make_immutable;

1;
