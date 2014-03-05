package CIF::Storage::SQL;

use strict;
use warnings;

use Mouse;
use DBIx::Connector;

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;
    
    $args->{'handle'} = DBIx::Connector->new(
        $args->{'dsn'},
        $args->{'username'} || '',
        $args->{'password'} || '',
        {
            RaiseError => $args->{'RaiseError'} || 0,
            AutoCommit => $args->{'AutoCommit'} || 0,
        },
    );

    return $self->$orig($args);
    
};

has [qw(dsn username password db)]   => (
    is      => 'ro',
    isa     => 'Str',
);

has [qw(AutoCommit RaiseError)]    => (
    is      => 'ro',
    isa     => 'Bool',
);

has 'handle' => (
    is      => 'ro',
    isa     => 'DBIx::Connector',
    reader  => 'get_handle',
);

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'plugin'});
    return 1 if($args->{'plugin'} eq 'sql');
}

sub shutdown { return 1; }

sub process {}

__PACKAGE__->meta()->make_immutable();

1;