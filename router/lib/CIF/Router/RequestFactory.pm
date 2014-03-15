package CIF::Router::RequestFactory;

use strict;
use warnings;

use Module::PluginFinder;
use Try::Tiny;
use Carp;

my $finder = Module::PluginFinder->new(
    search_path => 'CIF::Router::Request',
    filter      => sub {
        my ($class,$data) = @_;
        $class->understands($data);
    }
);

sub new_plugin {
    my ($self,$args) = @_;

    my ($ret,$err);
    try {
        $ret = $finder->construct($args->{'msg'},{%{$args}});
    } catch {
        $err = shift;
    };
    return $ret if($ret);
    return if($err =~ /^Unable to/);
    croak($err);
}

1;