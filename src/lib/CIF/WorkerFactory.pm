package CIF::WorkerFactory;

use strict;
use warnings;

use Carp;

use Module::Pluggable search_path => ['CIF::Worker'], 
      require => 1, 
      sub_name => '_worker_plugins',
      on_require_error => \&croak;
1;