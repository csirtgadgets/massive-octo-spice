package CIF::Client::Broker;

use strict;
use warnings;

use Mouse::Role;

use constant DEFAULT_AGENT_STRING => 'libcif/'.CIF::VERSION().' ('.CIF::ORG().')';
use constant DEFAULT_TIMEOUT => 300;

requires qw(send receive get_fd shutdown);

has 'agent' => (
    is      => 'rw',
    isa     => 'Str',
    default => DEFAULT_AGENT_STRING(),
    reader  => 'get_agent',
    writer  => 'set_agent',
);

has 'subscriber' => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_subscriber',
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
    reader  => 'get_max_retries',
    writer  => 'set_max_retries',
);

has 'timeout'   => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_timeout',
    default => DEFAULT_TIMEOUT(),
);

1;