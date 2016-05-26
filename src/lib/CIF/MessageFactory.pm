package CIF::MessageFactory;

use strict;
use warnings;

use Module::PluginFinder;

my $finder = Module::PluginFinder->new(
    search_path => 'CIF::Message',
    filter      => sub {
        my ($class,$data) = @_;
        $class->understands($data);
    }
);

sub new_plugin {
    my ($self,$args) = @_;

    (return $finder->construct($args,{%{$args}})) or die "I don't know how to create this type of Plugin";
}

1;
