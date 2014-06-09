package CIF::Smrt::Parser::Text;

use strict;
use warnings;

use Mouse;

# cif
use CIF qw(observable_type);

# other
use String::Tokenizer;
#use Lingua::EN::NamedEntity;

# http://search.cpan.org/~ambs/Lingua-NATools-v0.7.5/lib/Lingua/NATools.pm
# http://search.cpan.org/~tpederse/WordNet-Similarity-2.05/lib/WordNet/Similarity.pm
# http://perl.find-info.ru/perl/025/advperl2-chp-5-sect-4.html
# http://search.cpan.org/~bkb/Lingua-EN-ABC-0.02/lib/Lingua/EN/ABC.pm
# http://search.cpan.org/search?query=lingua%3a%3aen&mode=all
# https://metacpan.org/pod/Lingua::EN::Tagger
# https://metacpan.org/pod/Lingua::EN::NamedEntity

has 'handle' => (
    is      => 'ro',
    isa     => 'String::Tokenizer',
    default => sub { String::Tokenizer->new() },
    reader  => 'get_handle',
);

has 'remove_extra_whitespace'   => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    reader  => 'get_remove_extra_whitespace',
);

with 'CIF::Smrt::Parser';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 1 if($args->{'rule'}->{'parser'} eq 'text');
}

sub process {
    my $self = shift;
    my $args = shift;

    my $rv = [];
    foreach (@{$args->{'content'}}){
        # skip comments
        next if($self->get_rule()->get_skip_comments() && $_ =~ $self->get_rule()->get_comments());
        $_ =~ s/\s{2,}//g if($self->get_remove_extra_whitespace());
        
        $self->get_handle()->tokenize($_);
        foreach my $t ($self->get_handle()->getTokens()){
            next if($self->get_rule()->_ignore($t));
            next unless(observable_type($t));
            $t = { observable => $self->get_rule()->_replace($t) };
            if($self->get_rule()->get_store_content()){
                $t->{'additionaldata'} = [$_];
            }
            push(@$rv,$t);
        }      
    }
    return $rv;
}
__PACKAGE__->meta->make_immutable;

1;
