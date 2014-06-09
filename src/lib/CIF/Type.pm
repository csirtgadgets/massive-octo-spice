package CIF::Type;

use strict;
use warnings;

use Carp;
use Module::Pluggable search_path => 'CIF::Type', 
      require => 1,
      sub_name => 'load_cif_types',
      on_require_error => \&croak;

load_cif_types();

use Mouse::Util::TypeConstraints;

coerce 'ArrayRef',
    from 'Str',
    via { [ split(/,/,$_) ] };

no Mouse::Util::TypeConstraints;

1;
