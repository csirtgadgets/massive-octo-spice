#!perl

# http://www.matt-peters.com/blog/?p=35
# https://github.com/spiritloose/mod_psgi/

use lib '/vagrant/src/lib';

BEGIN {
    use FindBin;
    use local::lib "$FindBin::Bin/..";
}

use 5.014002;
use strict;
use warnings;

use Plack::Builder;
use CIF::Router::RESTApp;
use Config::Simple;
use Data::Dumper;

my $config = $CIF::EtcPath.'/default.conf';

if(-f $config){
    $config = Config::Simple->new($config)->get_block('client');
} else { $config = {}; }

my $rest = CIF::Router::RESTApp->new({
    %$config
});

builder {
    enable('REST',
        get             => sub { $rest->get(@_) },
        create          => sub { $rest->create(@_) }
    );
    sub { [501,[],[status_message(501)]] };
};