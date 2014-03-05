package CIF::Smrt::Decoder;

use warnings;
use strict;
use namespace::autoclean;

use Mouse::Role;

requires qw(understands process);

1;