#!/usr/bin/env bash
cat server.coffee \
server/DataSetsPresenter.coffee \
server/OrganismPresenter.coffee \
server/SummaryPresenter.coffee \
server/UploadPresenter.coffee | node_modules/.bin/coffee -sc | node