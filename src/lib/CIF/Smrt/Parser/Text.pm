package CIF::Smrt::Parser::Text;

use strict;
use warnings;

use Mouse;
use CIF qw(observable_type);
use String::Tokenizer;

# http://search.cpan.org/~ambs/Lingua-NATools-v0.7.5/lib/Lingua/NATools.pm
# http://search.cpan.org/~tpederse/WordNet-Similarity-2.05/lib/WordNet/Similarity.pm
# http://perl.find-info.ru/perl/025/advperl2-chp-5-sect-4.html
# http://search.cpan.org/~bkb/Lingua-EN-ABC-0.02/lib/Lingua/EN/ABC.pm
# http://search.cpan.org/search?query=lingua%3a%3aen&mode=all
# https://metacpan.org/pod/Lingua::EN::Tagger
# https://metacpan.org/pod/Lingua::EN::NamedEntity

has 'remove_extra_whitespace'   => (
    is      => 'ro',
    default => 0,
);

with 'CIF::Smrt::Parser';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 1 if($args->{'rule'}->{'parser'} eq 'text');
}

sub process {
    my $self = shift;
    my $data = shift;

    my $rv = [];
    my $otype;
    
    $data = [split(/\n/,$data)];
    
    my $tokenizer = String::Tokenizer->new();
    my $ignore = $self->rule->defaults->{'ignore'};
    if($ignore){
        $ignore = qr/$ignore/;
    }
    
    foreach (@$data){
        next unless($_);
        $_ =~ s/\s{2,}//g if($self->remove_extra_whitespace);
        
        $tokenizer->tokenize($_);
        foreach my $t ($tokenizer->getTokens()){
            next if($ignore && $t =~ $ignore);
            next unless(observable_type($t));
            $otype = observable_type($t);
            next unless($otype);
            $t = { 
            	observable => $t,
            	otype      => $otype
            };
            if($self->rule->store_content){
                $t->{'additionaldata'} = [$_];
            }
            push(@$rv,$t);
        }      
    }
    return $rv;
}
__PACKAGE__->meta->make_immutable;

1;
