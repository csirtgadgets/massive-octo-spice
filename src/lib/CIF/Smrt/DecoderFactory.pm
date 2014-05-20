package CIF::Smrt::DecoderFactory;

use strict;
use warnings;

use Module::PluginFinder;

my $finder = Module::PluginFinder->new(
    search_path => 'CIF::Smrt::Decoder',
    filter      => sub {
        my ($class,$data) = @_;
        $class->understands($data);
    }
);

sub new_plugin {
    my ($self,$args) = @_;
    return $finder->construct($args,%{$args}) or return 0;
}

1;