package CIF::Type::Protocol;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;
use CIF qw/protocol_to_int/;

subtype 'CIF::Type::Protocol',
    as 'Maybe[Int]',
    message { "Must be the protocol number" };
    
coerce 'CIF::Type::Protocol',
    from 'Str',
    via { protocol_to_int($_) };
    
no Mouse::Util::TypeConstraints;
1;