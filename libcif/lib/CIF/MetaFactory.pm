package CIF::MetaFactory;

use strict;
use warnings;

use Carp;

use Module::Pluggable search_path => ['CIF::Meta','CIFx::Meta'], 
      require => 1, 
      sub_name => '_meta_plugins',
      on_require_error => \&croak;
1;