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
    my $skip = $defaults->{'skip'};
    if($skip){
        delete($defaults->{'skip'});
    }
    
    my $cols = $defaults->{'values'};
    $cols = [$cols] unless(ref($cols));

    return unless($#{$data} > 0);
    assert($cols,'missing values param');
    assert($#{$data} > 0, 'no content to parse...');
    
    my @array;
    
    my $pattern = $defaults->{'pattern'};
    if(defined($pattern) && (!$defaults->{'parser'} || $defaults->{'parser'} eq 'default')){
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

        if ($skip){
            next if ($x =~ qr/$skip/);
        }
        chomp($x);
        $x =~ s/\s+$//g; # remove any trailing whitespace
        next unless($x =~ $pattern);

        @y = ();
        
        if(ref($pattern) eq 'Regexp' && (!$self->rule->{'parser'} || ($self->rule->{'parser'} && $self->rule->{'parser'} ne 'delim'))){
        	$x =~ $pattern;
        	my @loc = ();
        	push(@loc,$1) if($1);
        	push(@loc,$2) if($2);
        	push(@loc,$3) if($3);
        	push(@loc,$4) if($4);
        	push(@loc,$5) if($5);
        	push(@loc,$6) if($6);
        	push(@loc,$7) if($7);
        	push(@loc,$8) if($8);
        	push(@loc,$9) if($9);
        	push(@y,@loc);
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
