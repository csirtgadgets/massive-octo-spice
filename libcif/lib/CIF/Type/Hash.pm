package CIF::Type::Hash;

use strict;
use warnings;


use Mouse::Util::TypeConstraints;
use CIF qw/is_hash/;

subtype 'CIF::Type::Hash',
    as 'Str',
    where { is_hash($_) },
    message { "Not a valid hash: ".$_ };
    
coerce 'CIF::Type::Hash',
    from 'Str',
    via { lc() };
    
1;