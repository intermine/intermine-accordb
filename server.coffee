#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
winston  = require 'winston'
request  = require 'request'
imjs     = require 'imjs'
urlib    = require 'url'
fs       = require 'fs'
qs       = require 'querystring'
async    = require 'async'

winston.cli()

# Queries in JSON.
json = fs.readFileSync './queries.json'
try
    Queries = JSON.parse json
catch err
    throw err.message.red

# We are booting.
state = 1
# Based on the state the app is in, serve a different landing page.
stateHandler = (req, res, next) ->
    # Are we requesting the index.html page?
    if req.url is '/'
        switch state
            # Offline.
            when 0 then req.url = '/offline.html'
            # Booting.
            when 1 then req.url = '/loading.html'

    next()

# Internal storage.
DB = {}

# Mine connection.
url = 'http://intermine.org/mastermine-preview'
mine = new imjs.Service
    'root': url
    'errorHandler': (err) ->
        if err.message
            winston.error err.message
        else
            winston.error err

# Fetch datasets & check that InterMine is online.
do boot = ->
    winston.info 'Fetching homologue datasets'
    mine.query Queries.homologueDataSets, (qq) ->
        qq.rows (dataSets) ->
            DB.dataSets = (x[0] for x in dataSets)
            winston.info 'Ready'.green.bold
            # We are online.
            state = 2

    .fail (err) ->
        # We are offline.
        winston.error 'Offline'.red.bold
        state = 0

        # Check again in a minute.
        setTimeout boot, 6e4

# Config filters.
app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        stateHandler
        connect.static __dirname + '/public'
    ]

# Start the server app.
app.start process.env.PORT, (err) ->
    throw err if err
    winston.info "Listening on port #{app.server.address().port}".green

# -------------------------------------------------------------------

# Get back the homologue datasets we can use.
app.router.path '/api/datasets', ->
    @get ->
        winston.info "Get homologue datasets"

        @res.writeHead 200, "content-type": "application/json"
        @res.write JSON.stringify
            'dataSets': DB.dataSets
        @res.end()

# Resolve identifiers and show counts in datasets.
app.router.path '/api/upload', ->
    @post ->
        req = @req

        async.waterfall [ (cb) ->
            winston.info "Resolve gene symbols into homologues"

            return cb 'Need to provide form data' unless req.body?

            identifiers = (x for x in req.body['gene-identifiers'].replace(/\,/g, '').replace(/\s{2,}/g, ' ').split(' '))
            cb null, identifiers

        (identifiers, cb) ->
            winston.info "Posting identifiers " + new String(identifiers).blue

            request
                'uri':    "#{url}/service/ids"
                'method': "POST"
                'json':
                    'identifiers': identifiers
                    'type':        'Gene'
            , cb

        (res, body, cb) ->
            job = body.uid
            winston.info "Checking job #{job}"

            do checkJob = ->
                request
                    'uri':    "#{url}/service/ids/#{job}/status"
                    'method': "GET"
                , (err, res, body) ->
                    return cb err if err

                    try
                        body = JSON.parse body
                    catch e
                        return cb e

                    winston.info "Job #{job} says #{body.status}"

                    switch body.status
                        when 'SUCCESS' then cb null, job
                        when 'ERROR' then cb body.message
                        when null then cb body.error
                        else setTimeout checkJob, 5e2 # check in half a second

        (job, cb) ->
            winston.info "Getting result of job #{job}"

            request
                'uri':    "#{url}/service/ids/#{job}/result"
                'method': "GET"
            , cb

        (res, body, cb) ->
            ids = (key for key, value of JSON.parse(body).results)

            # Empty results.
            if not ids.length > 0
                winston.info 'No identifiers resolved'.yellow
                return cb 'None of the identifiers were resolved'
            else
                winston.info "Getting homologues for genes"
                
                query = JSON.parse JSON.stringify Queries.homologuesForGenes

                # Identifiers received through resolution service.
                query.where.push [ 'id', 'ONE OF', ids ]

                # Gene organism constraint.
                query.where.push [ 'organism.name', '=', req.body['gene-organism'] ]

                # Homologue dataset constraint?
                if req.body['dataset'] isnt '*'
                    query.where.push [ 'homologues.dataSets.name', '=', req.body['dataset'] ]

                # Choose homologue organism.
                if (homologueOrganismName = req.body['homologue-organism']) is '*'
                    # Exclude paralogs if all other organisms selected.
                    query.where.push [ 'homologues.homologue.organism.name', 'ONE OF',
                        homologueOrganisms = ( x for x in Queries.organisms when x isnt req.body['gene-organism'] )
                    ]
                else
                    query.where.push [ 'homologues.homologue.organism.name', '=', homologueOrganismName ]
                    homologueOrganisms = [ homologueOrganismName ]

                mine.query query, (q) =>
                    winston.info q.toXML().blue
                    
                    q.rows (data) =>
                        winston.info "Reorganizing the rows"

                        # This is where we store the resulting collection.
                        results = {}
                        # Traverse the gene rows returned.
                        for row in data
                            # Identifier is the symbol (preferred) or the internal id.
                            id = row[1] or row[0]
                            # Init the skeleton structure.
                            if not results[id]?
                                results[id] =
                                    'organism': row[2]
                                    'homologues': {}
                                
                                # Fill it up with homologue organisms
                                for organismName in homologueOrganisms
                                    results[id]['homologues'][organismName] = {}

                                # Fill it up with dataset arrays per homologue organism.
                                for org, v of results[id]['homologues']
                                    if req.body['dataset'] isnt '*'
                                        results[id]['homologues'][org][req.body['dataset']] = []
                                    else
                                        for dataSet in DB.dataSets
                                            results[id]['homologues'][org][dataSet] = []

                            # Push the homologue object.
                            results[id]['homologues'][row[5]][row[6]].push
                                'primaryIdentifier': row[3]
                                'symbol':            row[4]

                        if Object.keys(results).length is 0
                            winston.info 'No data to return'.yellow

                            return cb 'None of the identifiers match the organism or its homologues'
                        
                        winston.info 'Returning back the rows'

                        cb null,
                            'query':   q.toXML()
                            'results': results
                            'meta':
                                'homologues': homologueOrganisms
                                'dataSets': if req.body['dataset'] is '*' then DB.dataSets else [ req.body['dataset'] ]

        ], (err, results) =>
            if err
                if err.message then err = err.message
                
                winston.error err

                @res.writeHead 500, 'content-type': 'application/json'
                @res.write JSON.stringify 'message': err
                @res.end()
            else
                winston.info 'Done'.green.bold

                @res.writeHead 200, 'content-type': 'application/json'
                @res.write JSON.stringify results
                @res.end()