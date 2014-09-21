package CIF::Smrt::Parser::Xml;

use strict;
use warnings;
use XML::LibXML;
use Mouse;
use CIF qw/$Logger/;
use Data::Dumper;

with 'CIF::Smrt::Parser';

sub understands { 
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} eq 'xml');
}

sub process {
    my $self = shift;
    my $data = shift;
    
    $Logger->debug('parsing as XML....');
    
    my $defaults = $self->rule->defaults;
    
    my $parser      = XML::LibXML->new();
    my $doc         = $parser->load_xml(string => $data);
    my @nodes       = $doc->findnodes('//'.$defaults->{'node'});
    my @map         = @{$defaults->{'map'}};
    my @values      = @{$defaults->{'values'}};
    
    my (@array,$h);
    foreach my $node (@nodes){
        $h = undef;
        foreach my $e (0 ... $#map){
            my $x = $node->findvalue('./'.$map[$e]);
            $h->{$values[$e]} = $x;
        }
        if($h->{'observable'}){
            push(@array,$h); ## TODO- push a 'required' field into the config?
        } else {
            $Logger->error('feed missing observable, skipping..');
        }
    }
    return(\@array);
}

1;
