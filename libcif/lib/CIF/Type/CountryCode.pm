package CIF::Type::CountryCode;

use strict;
use warnings;
use namespace::autoclean;

use Mouse::Util::TypeConstraints;

subtype "CIF::Type::CountryCode", 
    as 'Str',
    where { /^[A-Z]{2}$/ },
    message { "Must be two letter country code (eg: US, CN, etc..): ".$_ };

coerce 'CIF::Type::CountryCode',
    from 'Str',
    via { uc };

1;