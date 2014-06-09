package CIF::Smrt::Parser::Xml;

use strict;
use warnings;
require XML::LibXML;

use Mouse;

with 'CIF::Smrt::Parser';

sub process {}

sub understands {}

sub parse {
    my $f = shift;
    my $content = shift;
    
    my $parser      = XML::LibXML->new();
    my $doc         = $parser->load_xml(string => $content);
    my @nodes       = $doc->findnodes('//'.$f->{'node'});
    my @subnodes    = $doc->findnodes('//'.$f->{'subnode'}) if($f->{'subnode'});
    
    return unless(@nodes);
    
    my @array;
    my @elements        = split(',', $f->{'elements'})       if($f->{'elements'});
    my @elements_map    = split(',', $f->{'elements_map'})   if($f->{'elements_map'});
    my @attributes_map  = split(',', $f->{'attributes_map'}) if($f->{'attributes_map'});
    my @attributes      = split(',', $f->{'attributes'})     if($f->{'attributes'});
    
    my %regex;
    foreach my $k (keys %$f){
        # pull out any custom regex
        for($k){
            if(/^regex_(\S+)$/){
                $regex{$1} = qr/$f->{$k}/;
                delete($f->{$k});
                last;
            }
            # clean up the hash, so we can re-map the default values later
            if(/^(elements_?|attributes_?|node|subnode)/){
                delete($f->{$k});
                last;
            }
        }
    }
   
    foreach my $node (@nodes){
        my $h = {};
        map { $h->{$_} = $f->{$_} } keys %$f;
        my $found = 0;
        if(@elements_map){
            foreach my $e (0 ... $#elements_map){
                my $x = $node->findvalue('./'.$elements[$e]);
                next unless($x);
                if(my $r = $regex{$elements[$e]}){
                    if($x =~ $r){
                        $h->{$elements_map[$e]} = $x;
                        $found = 1;
                    } else {
                        $found = 0;
                    }
                } else {
                    $h->{$elements_map[$e]} = $x;
                    $found = 1;
                }
            }
        } else {
            foreach my $e (0 ... $#attributes_map){       
                my $x = $node->getAttribute($attributes[$e]);
                next unless($x);
                if(my $r = $regex{$attributes[$e]}){
                    if($x =~ $r){
                        $h->{$attributes_map[$e]} = $x;
                        $found = 1;
                    } else {
                        $found = 0;
                    }
                } else {
                    $h->{$attributes_map[$e]} = $x;
                    $found = 1;
                }
            }
        }
        push(@array,$h) if($found);
    }
    return(\@array);
}

1;
