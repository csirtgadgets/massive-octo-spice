package CIF::Type;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

use Carp;
use Module::Pluggable search_path => 'CIF::Type', 
      require => 1, 
      sub_name => 'load_cif_types',
      on_require_error => \&croak;

# load plugins
# require auto-loads for us
load_cif_types();

coerce 'ArrayRef',
    from 'Str',
    via { [ split(/,/,$_) ] };

1;
