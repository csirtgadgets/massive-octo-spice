package CIF::Type::UpperCaseStr;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype "CIF::Type::UpperCaseStr", 
    as 'Str',
    where { /\p{Upper}/ms },
    message { "Must be uppercase." };

coerce 'CIF::Type::UpperCaseStr',
    from 'Str',
    via { uc };
    
no Mouse::Util::TypeConstraints;

1;