#!/bin/bash

set -e

echo 'installing marvel....'
sudo /usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/latest

echo 'marvel ready on http://localhost:9200/_plugin/marvel'
