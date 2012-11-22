#!/usr/bin/env bash

# chaplin
./client.sh

# flatiron
cat server.coffee \
server/DataSetsPresenter.coffee \
server/OrganismPresenter.coffee \
server/SummaryPresenter.coffee \
server/UploadPresenter.coffee | ./node_modules/coffee-script/bin/coffee -sc | node