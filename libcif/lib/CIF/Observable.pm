package CIF::Observable;

use strict;
use warnings;


use Mouse::Role;
use CIF qw/debug hash_create_random observable_type/;
use CIF::Type;
use Time::HiRes qw/tv_interval/;
use Data::Dumper;
use Carp;

requires qw(understands process);

has 'lang' => (
    is      => 'rw',
    isa     => 'CIF::Type::UpperCaseStr',
    default => 'EN',
    coerce  => 1,
);

has 'id' => (
    is        => 'ro',
    isa       => 'Str',
    default   => sub { hash_create_random() },
);

has 'provider' => (
    is      => 'ro',
    isa       => 'CIF::Type::LowerCaseStr',
    coerce    => 1,
);

has 'group' => (
    is      => 'ro',
    isa     => 'CIF::Type::LowerCaseStr',
    default => CIF::DEFAULT_GROUP(),
    coerce  => 1,
    reader  => 'get_group',
);

has 'tlp' => (
    is      => 'ro',
    isa     => 'CIF::Type::Tlp',
    coerce  => 1, 
);

has 'confidence' => (
    is      => 'ro',
    isa     => 'Num',
);

has 'tags'  => (
    is      => 'ro',
    isa     => 'ArrayRef',
    coerce  => 1,
);

has 'observable' => (
    is      => 'ro',
    isa     => 'CIF::Type::LowerCaseStr',
    coerce  => 1,
    reader  => 'get_observable',
);

has 'otype'   => (
    is          => 'ro',
    isa         => 'CIF::Type::LowerCaseStr',
    default     => sub { observable_type($_[0]->get_observable()) },
    required    => 1,
    reader      => 'get_otype',
);

has [qw(reporttime firsttime lasttime)] => (
    is      => 'ro',
    isa     => 'Int',
    coerce  => 1,
    default => sub { time() },
);

has 'relatedid' => (
    is      => 'ro',
    isa     => 'CIF::Type::LowercaseStr',
    coerce  => 1, 
);

has 'altid'     => (
    is  => 'ro',
    isa => 'Str',
);

has 'altid_tlp' => (
    is  => 'ro',
    isa => 'CIF::Type::Tlp',
);

has 'additional_data' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    coerce  => 1,
);

sub TO_JSON {
    my $self = shift;
    
    return {%$self};
}

1;
