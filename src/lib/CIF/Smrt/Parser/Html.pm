package CIF::Smrt::Parser::Html;

use strict;
use warnings;
use HTML::TableExtract;
use Mouse;
use CIF qw/$Logger/;
use Data::Dumper;

with 'CIF::Smrt::Parser';

sub understands { 
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} eq 'html');
}

sub process {
    my $self = shift;
    my $data = shift;
    
    $Logger->debug('parsing as HTML....');
    
    my $defaults = $self->rule->defaults;
    my @map = @{$defaults->{'map'}};
    my @values = @{$defaults->{'values'}};
    
    my $t = HTML::TableExtract->new(headers => $defaults->{'map'});
    $t->parse($data);
    
    my (@array,$h);
    foreach my $ts ($t->tables()){
        foreach my $row ($ts->rows()){
            $h = {}; # more efficient mem
            foreach my $x (0 .. $#map){
                next if($values[$x] eq 'null');
                $h->{$values[$x]} = @{$row}[$x];
            }
            if($h->{'observable'}){
                push(@array,$h); ## TODO- push a 'required' field into the config?
            } else {
                $Logger->error('feed missing observable, skipping..');
            }
        }
    }
    return(\@array);
}

1;
