package CIF::Smrt::Parser::Default;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use Carp::Assert;

with 'CIF::Smrt::Parser';

use constant RE_SUPPORTED_PARSERS => qw/^(delim|csv|pipe|default)$/;

sub understands {
    my $self = shift;
    my $args = shift;

    return 1 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} =~ RE_SUPPORTED_PARSERS());
}


sub process {
    my $self = shift;
    my $args = shift;

    my $cols = $self->get_rule()->get_values();

    return unless($#{$args->{'content'}} > 0);
    assert($cols,'missing values param');
    assert($#{$args->{'content'}} > 0, 'no content to parse...');
    
    my @array;
    
    my $pattern = $self->get_rule()->get_pattern();
    
    if(defined($pattern)){
        $pattern = qr/$pattern/;
    } else {
        for($self->get_rule()->get_parser()){
            if(/^csv$/){
                $pattern = ',';
                last;
            }
            if(/^pipe$/){
                $pattern = '\||\s+\|\s+';
                last;
            }
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
        @y = ();
        if(ref($pattern) eq 'Regexp'){
        	$x =~ $pattern;
        	push(@y,($1,$2));
        } else {
            @y = split($pattern,$x);
        }
        ##TODO refactor
        if($self->get_rule()->get_parser() eq 'default'){
            
        } else {
            # if we're dealing with csv, strip the ""'s if they exist
            if($self->get_rule()->get_parser() eq 'csv'){
                s/"//g foreach(@y);
            }
            
        }
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
