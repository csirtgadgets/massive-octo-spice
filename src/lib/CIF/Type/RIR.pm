package CIF::Type::RIR;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype 'CIF::Type::RIR',
    as 'Str',
    where { /^(arin|apnic|ripencc|lacnic|afrinic)$/ },
    message { "Not a valid RIR: ".$_ };
    
coerce 'CIF::Type::RIR',
    from 'Str',
    via { lc() };

no Mouse::Util::TypeConstraints;
1;