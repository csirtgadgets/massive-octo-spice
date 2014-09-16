package CIF::Smrt::Parser::Default;

use strict;
use warnings;

use Mouse;
use Carp::Assert;

with 'CIF::Smrt::Parser';

use constant RE_SUPPORTED_PARSERS => qw/^(delim|csv|pipe|default)$/;
use constant RE_COMMENTS => qr/^([#|;]+)/;

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 1 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} =~ RE_SUPPORTED_PARSERS());
}

sub process {
    my $self    = shift;
    my $data    = shift;
    
    $data = [split(/\n/,$data)];
    
    my $defaults = $self->rule->defaults;
    
    my $cols = $defaults->{'values'};
    $cols = [$cols] unless(ref($cols));

    return unless($#{$data} > 0);
    assert($cols,'missing values param');
    assert($#{$data} > 0, 'no content to parse...');
    
    my @array;
    
    my $pattern = $defaults->{'pattern'};
    if(defined($pattern) && !$defaults->{'parser'}){
        $pattern = qr/$pattern/;
    } else {
        my $parser = $self->rule->{'parser'} || '';
        for($parser){
            if(/^csv$/){
                $pattern = ',';
                last;
            }
            if(/^pipe$/){
                $pattern = '\||\s+\|\s+';
                last;
            }
            if(/^delim$/){
                last; # do nothing
            }
        }
    }
    my ($start,$end) = (0,$#{$data});
    if($defaults->{'limit'}){
        $end = $defaults->{'limit'};
    }
    if($defaults->{'start'}){
        $start = ($defaults->{'start'} - 1);
    }
    if($defaults->{'end'}){
        $end = ($defaults->{'end'} - 1);
    }

    if($self->rule->skip){
        $start = ($start + $self->rule->skip);
        $end = ($end + $self->rule->skip);
    }
    
    my ($x,@y,$z);

    for (my $i = $start; $i <= $end; $i++){ 
        $x = @{$data}[$i];
        next if($x =~ RE_COMMENTS);
        chomp($x);
        next unless($x =~ $pattern);
        @y = ();
        if(ref($pattern) eq 'Regexp'){
        	$x =~ $pattern;
        	push(@y,($1,$2,$3)); ## TODO -- finish me
        } else {
            @y = split($pattern,$x);
        }
        
        if($self->rule->parser && $self->rule->parser eq 'csv'){
             s/"//g foreach(@y);
        }
        $z = undef;
        if($#{$cols} > 0){
            foreach (0 ... $#{$cols}){
                next if($cols->[$_] eq 'null');
                $z->{$cols->[$_]} = $y[$_];
            }
        } else {
            $z->{$cols->[0]} = $y[0];
        }
        if($self->rule->store_content){
                $z->{'additionaldata'} = [$x];
        }
        push(@array,$z);
    }
    return(\@array);
}

__PACKAGE__->meta->make_immutable;

1;
