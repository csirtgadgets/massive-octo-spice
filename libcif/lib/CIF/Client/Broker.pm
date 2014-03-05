package CIF::Client::Broker;

use strict;
use warnings;

use Mouse::Role;

use constant DEFAULT_AGENT_STRING => 'libcif/'.$CIF::VERSION.' (csirtgadgets.org)';

has 'agent' => (
    is      => 'rw',
    isa     => 'Str',
    default => DEFAULT_AGENT_STRING(),
    reader  => 'get_agent',
    writer  => 'set_agent',
);

has 'remote' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_remote',
);

has 'token' => (
    is      => 'ro',
    isa     => 'Str',
);

has 'is_connected' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    reader  => 'get_is_connected',
    writer  => 'set_is_connected',
);

has 'heartbeat' => (
    is      => 'ro',
    isa     => 'Int',
    default => 30,
);

has 'max_retries' => (
    is      => 'rw',
    isa     => 'Int',
    default => 5,
);

has 'timeout'   => (
    is      => 'ro',
    isa     => 'Int',
    default => 300,
);

1;