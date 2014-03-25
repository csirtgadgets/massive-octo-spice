package CIF::Smrt;

use 5.011;
use strict;
use warnings;

use Mouse;

# cif support
use CIF qw/hash_create_random debug normalize_timestamp is_ip/;
require CIF::Client;
require CIF::ObservableFactory;
require CIF::RuleFactory;
require CIF::Smrt::HandlerFactory;

use Data::Dumper;
use Config::Simple;
use Carp::Assert;

use constant MAX_DATETIME => 999999999999999999;

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

has 'test_mode' => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_test_mode',
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
            rule        => $self->get_rule(),
            test_mode   => $self->get_test_mode(),
        }),
    );

    my $ret = $self->get_handler()->process($self->get_rule());
    return unless($ret);
    
    my @array;  
    debug('building events: '.($#{$ret} + 1));
    my $ts;
    # threading start here?
    foreach (@$ret){
        $ts = $_->{'detecttime'} || $_->{'reporttime'} || MAX_DATETIME();
        $ts = normalize_timestamp($ts)->epoch();

        next unless($self->get_rule()->get__not_before() <= $ts );
        $self->get_rule()->process({ data => $_ });
        push(@array,$_);
    }
    return \@array;
}

# threading goes here.
sub _process {
    my $self = shift;
    my $args = shift;
    
       
}


__PACKAGE__->meta->make_immutable();

1;
