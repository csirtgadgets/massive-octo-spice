package CIF::Encoder;

use strict;
use warnings;
use namespace::autoclean;

use Mouse::Role;

requires qw(encode decode understands);

1;