package CIF::Smrt::Parser::Rss;

use strict;
use warnings;
use XML::RSS;

use Mouse;

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
    my $args = shift;
    
    my $content = $args->{'content'};
    my $f;
    
    # work-around for any < > & that is in the feed as part of a url
    # http://stackoverflow.com/questions/5199463/escaping-in-perl-generated-xml/5899049#5899049
    # needs some work, the parser still pukes.
    foreach(@{$content}){
        s/(\S+)<(?!\!\[CDATA)(.*<\/\S+>)$/$1&#x3c;$2/g;
        s/^(<.*>.*)(?<!\]\])>(.*<\/\S+>)$/$1&#x3e;$2/g;
    }
    $content = join("\n",@$content);

    # fix malformed RSS
    unless($content =~ /^<\?xml version/){
        $content = '<?xml version="1.0"?>'."\n".$content;
    }

    my $rss = XML::RSS->new();
    
    $rss->parse($content);
    
    my @array;
    foreach my $item (@{$rss->{items}}){
        my $h;
        foreach my $key (keys %$item){
            if(my $r = $f->{'regex_'.$key}){
                my @m = ($item->{$key} =~ /$r/);
                my @cols = split(',',$f->{'regex_'.$key.'_values'});
                foreach (0 ... $#cols){
                    $h->{$cols[$_]} = $m[$_];
                }
            }
        }
        map { $h->{$_} = $f->{$_} } keys %$f;
        push(@array,$h);
    }
    return(\@array);

}

1;
