#!/usr/bin/env bash
export PATH=$PATH:node_modules/coffee-script/bin/

cat server.coffee \
server/DataSetsPresenter.coffee \
server/OrganismPresenter.coffee \
server/SummaryPresenter.coffee \
server/UploadPresenter.coffee | coffee -sc | node