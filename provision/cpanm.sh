#!/bin/bash

set -e

FLAG=/tmp/.provisioned_cpanm
PERLBREW_ROOT=/home/vagrant/perl5/perlbrew

if [ -e $FLAG ]; then
    echo 'already provisioned cpanm...'
    exit
fi

. ${PERLBREW_ROOT}/etc/bashrc

cpanm -n -f -q Config::Tiny Regexp::Common::net Mail::RFC822::Address Carp::Assert DateTime::Format::DateParse Text::Table Snort::Rule Log::Dispatch URI Time::HiRes Digest::SHA Module::PluginFinder ZMQ::FFI ZMQx::Class LWP::UserAgent LWPx::ParanoidAgent Net::SSL Search::Elasticsearch ElasticSearch::SearchBuilder MouseX::Foreign Net::DNS::Match Crypt::Random::Source Regexp::IPv6 Test::Perl::Critic XML::LibXML File::Type Module::PluginFinder XML::RSS String::Tokenizer Compress::Snappy JSON::XS Config::Simple DBIx::Connector Try::Tiny Mouse Test::TCP Test::SharedFork Net::Patricia DBD::SQLite Config::Auto Config::JSON Plack::Runner Net::Abuse::Utils Module::Install Class::CSV

touch $FLAG
