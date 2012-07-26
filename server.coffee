#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
request  = require 'request'
imjs     = require 'imjs'
urlib    = require 'url'
fs       = require 'fs'
qs       = require 'querystring'

# Queries in JSON.
json = fs.readFileSync './server/queries.json'
try
    Queries = JSON.parse json
catch err
    throw err.message.red

# -------------------------------------------------------------------
# Config filters.

app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        connect.static __dirname + '/public'
    ]

# Internal storage.
DB = {}

# Mine connection.
url = 'http://test.metabolicmine.org/mastermine-test'
mine = new imjs.Service root: url

# Deep copy object.
clone = (obj) ->
    if not obj? or typeof obj isnt 'object'
        return obj
    
    newInstance = new obj.constructor()

    for key of obj
        newInstance[key] = clone obj[key]

    newInstance

# -------------------------------------------------------------------
# Start the server app.
app.start 4000, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}".green

    app.log.info "Fetching homologue datasets".grey
    mine.query Queries.homologueDataSets, (qq) =>
        qq.rows (dataSets) =>
            DB.dataSets = (x[0] for x in dataSets)