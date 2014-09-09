package CIF::Smrt::Parser::Rss;

use strict;
use warnings;
use XML::RSS;

use Mouse;
use CIF qw/$Logger/;

with 'CIF::Smrt::Parser';

##TODO: 
# https://github.com/justfalter/cif-v1/tree/v1_fork/lib/CIF/Smrt/ParserHelpers
# https://github.com/justfalter/cif-v1/blob/v1_fork/lib/CIF/Smrt/Parsers/ParseXPath.pm

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'rule'}->{'parser'});
    return 1 if($args->{'rule'}->{'parser'} eq 'rss');
}

sub process {
    my $self = shift;
    my $data = shift;
    
    $Logger->debug('parsing as RSS....');
    
    $data = _normalize($data);
    
    my $defaults = $self->rule->defaults;
    
    my $patterns = $defaults->{'pattern'};

    my $rss = XML::RSS->new();
    
    $rss->parse($data);
    
    my @array;
    foreach my $item (@{$rss->{items}}){
        my $h;
        foreach my $key (keys %$item){
            if(my $r = $patterns->{$key}){
                my $pattern = qr/$r->{'pattern'}/;
                my @m = ($item->{$key} =~ $pattern);
                my @cols = $r->{'values'};
                foreach (0 ... $#cols){
                    $h->{$cols[$_]} = $m[$_];
                }
            }
        }
        map { $h->{$_} = $defaults->{$_} } keys %{$defaults};
        delete($h->{'pattern'});
        push(@array,$h);
    }
    return(\@array);
}

sub _normalize {
    my $data = shift;
    
    # work-around for any < > & that is in the feed as part of a url
    # http://stackoverflow.com/questions/5199463/escaping-in-perl-generated-xml/5899049#5899049
    # needs some work, the parser still pukes.
    $data =~ s/(\S+)<(?!\!\[CDATA)(.*<\/\S+>)$/$1&#x3c;$2/g;
    $data =~ s/^(<.*>.*)(?<!\]\])>(.*<\/\S+>)$/$1&#x3e;$2/g;
   
    # fix malformed RSS
    unless($data =~ /^<\?xml version/){
        $data = '<?xml version="1.0"?>'."\n".$data;
    }
    
    return $data;
}

1;
