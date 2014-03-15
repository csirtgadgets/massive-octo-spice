package CIF::Smrt;

use 5.011;
use strict;
use warnings;

use Mouse;

# cif support
use CIF qw/hash_create_random debug normalize_timestamp/;
require CIF::Client;
require CIF::ObservableFactory;
require CIF::RuleFactory;
require CIF::Smrt::HandlerFactory;
use Data::Dumper;
use Config::Simple;
use Carp::Assert;

has 'config'    => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'client_config' => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'client' => (
    is      => 'ro',
    isa     => 'CIF::Client',
    reader  => 'get_client',
);

has 'is_test'   => (
    is      => 'ro',
    isa     => 'Bool',
);

has 'other_attributes'  => (
    is      => 'ro',
    isa     => 'HashRef',
);

has 'handler'   => (
    is      => 'rw',
    reader  => 'get_handler',
    writer  => 'set_handler',
);

has 'rule'   => (
    is      => 'rw',
    writer  => 'set_rule',
    reader  => 'get_rule',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;   

    if($args->{'config'}){
        die "config file doesn't exist: ".$args->{'config'} unless(-e $args->{'config'});
        $args->{'client_config'} = Config::Simple->new($args->{'config'})->get_block('client');
        $args->{'config'} = Config::Simple->new($args->{'config'})->get_block('smrt');
        $args = { %{$args->{'config'}},  %$args };
    }
    
    if($args->{'client_config'}){
        $args->{'client'} = CIF::Client->new($args->{'client_config'});   
    }
 
    return $self->$orig($args);
};

sub process {
    my $self = shift;
    my $args = shift;

    $self->set_rule(
        CIF::RuleFactory->new_plugin($args->{'rule'})
    );

    $self->set_handler(
        CIF::Smrt::HandlerFactory->new_plugin({
            rule => $self->get_rule(),
        }),
    );
    
    my $ret = $self->get_handler()->process($self->get_rule());
    assert($ret,'handler failed');
    
    debug('building events...');
    map { $self->get_rule()->process({ data => $_ }) } @$ret;
    return $ret;
}


__PACKAGE__->meta->make_immutable();

1;
