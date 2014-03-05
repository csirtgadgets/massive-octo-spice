#!/bin/bash

set -e

FLAG=/tmp/.provisioned_cpanm

if [ -e $FLAG ]; then
    echo 'already provisioned cpanm...'
    exit
fi

cpanm Mouse Try::Tiny Regexp::Common::net Mail::RFC822::Address.pm Compress::Snappy JSON::XS Carp::Assert DateTime::Format::DateParse Text::Table Snort::Rule Log::Dispatch URI Time::HiRes Digest::SHA Module::PluginFinder Config::Simple ZMQx::Class LWP::UserAgent LWPx::ParanoidAgent Net::SSL ElasticSearch ElasticSearch::SearchBuilder MouseX::Foreign Net::Patricia Net::DNS::Match DBIx::Connector DBD::SQLite Crypt::Random::Source Regexp::IPv6 Test::Perl::Critic XML::LibXML File::Type Module::PluginFinder XML::RSS String::Tokenizer

touch $FLAG
