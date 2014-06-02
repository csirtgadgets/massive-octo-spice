package CIF::Type::LowerCaseStr;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype "CIF::Type::LowerCaseStr", 
    as 'Str',
    where { !/\p{Upper}/ms },
    message { "Must be lowercase." };

coerce 'CIF::Type::LowerCaseStr',
    from 'Str',
    via { lc };

no Mouse::Util::TypeConstraints;

1;