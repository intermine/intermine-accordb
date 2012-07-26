#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
request  = require 'request'
imjs     = require 'imjs'
urlib    = require 'url'
fs       = require 'fs'
qs       = require 'querystring'

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

# -------------------------------------------------------------------
# Organisms we are interested in throughout.
Organisms = [
    'Caenorhabditis elegans'
    'Danio rerio'
    'Drosophila melanogaster'
    'Homo sapiens'
    'Mus musculus'
    'Rattus norvegicus'
    'Saccharomyces cerevisiae'
]

# Queries we will be using throughout.
Queries =
    'homologueDataSets':
        model:
            name: "genomic"
        select: [ "Gene.homologues.dataSets.name" ]
        orderBy: [ "Gene.homologues.dataSets.name": "ASC" ]
    
    'homologuesForGenes':
        from: "Gene"
        # List source gene and then homologue ending with dataset name.
        select: [
            "primaryIdentifier",
            "symbol",
            "organism.name",
            "homologues.homologue.primaryIdentifier",
            "homologues.homologue.symbol",
            "homologues.homologue.organism.name",
            "homologues.dataSets.name"
        ]
        where: []
        # Order by gene primary identifier > homologue organism > homologue dataset.
        sortOrder: [
            path: 'primaryIdentifier'
            direction: 'ASC'
        ,
            path: 'homologues.homologue.organism.name'
            direction: 'ASC'
        ,
            path: 'homologues.dataSets.name'
            direction: 'ASC'
        ]

    'summary':
        from: "Gene"
        select: [
            "primaryIdentifier"
            "homologues.dataSets.name"
            "homologues.homologue.organism.name"
        ]
        where: [
           [ "symbol", '=', 'CDC*' ]
        ]
        sortOrder: [
            path: 'homologues.homologue.organism.name'
            direction: 'ASC'
        ]

    'organismOverlap':
        from: "Gene"
        select: [ "organism.name", "homologues.homologue.organism.name", "id", "homologues.dataSets.name", "homologues.homologue.id" ]
        where: [
            [ "organism.name", "ONE OF", Organisms ]
        ,
            [ "homologues.homologue.organism.name", "ONE OF", Organisms ]
        ,
            [ "homologues.homologue.symbol", "=", "CDC*" ]
        ]

# -------------------------------------------------------------------
# Get back the homologue datasets we can use.
app.router.path '/api/datasets', ->
    @get ->
        app.log.info "Get homologue datasets"

        @res.writeHead 200, "content-type": "application/json"
        @res.write JSON.stringify
            'dataSets': DB.dataSets
        @res.end()        

# Resolve identifiers and show counts in datasets.
app.router.path '/api/upload', ->
    @post ->
        app.log.info "Resolve gene symbols into homologues"

        if not @req.body?
            app.log.info 'Need to provide form data'.red 

            @res.writeHead 400, "content-type": "application/json"
            @res.write JSON.stringify 'message': 'Need to provide form data'
            @res.end()

        identifiers = (x for x in @req.body['gene-identifiers'].replace(/\,/g, '').replace(/\s{2,}/g, ' ').split(' '))

        app.log.info "Posting identifiers ".grey + new String(identifiers).blue

        request
            'uri':    "#{url}/service/ids"
            'method': "POST"
            'json':
                'identifiers': identifiers
                'type':        'Gene'
        , (err, res, body) =>
            throw err if err

            job = body.uid
            do checkJob = =>
                app.log.info "Checking job #{job}".grey
                request
                    'uri':    "#{url}/service/ids/#{job}/status"
                    'method': "GET"
                , (err, res, body) =>
                    throw err if err

                    body = JSON.parse(body)

                    app.log.info "Job #{job} says #{body.status}".grey

                    switch body.status
                        when 'SUCCESS'
                            app.log.info "Getting result of job #{job}".grey

                            request
                                'uri':    "#{url}/service/ids/#{job}/result"
                                'method': "GET"
                            , (err, res, body) =>
                                throw err if err

                                ids = (key for key, value of JSON.parse(body).results)

                                # Empty results.
                                if not ids.length > 0
                                    app.log.info 'No identifiers resolved'.yellow
                                    @res.writeHead 500
                                    @res.end()
                                else
                                    app.log.info "Getting homologues for genes".grey
                                    
                                    query = clone Queries.homologuesForGenes

                                    # Identifiers received through resolution service.
                                    query.where.push [ "id", "ONE OF", ids ]

                                    # Gene organism constraint.
                                    query.where.push [ "organism.name", "=", @req.body['gene-organism'] ]

                                    # Homologue dataset constraint?
                                    if @req.body['dataset'] isnt '*'
                                        query.where.push [ "homologues.dataSets.name", "=", @req.body['dataset'] ]

                                    # Choose homologue organism.
                                    switch homologueOrganismName = @req.body['homologue-organism']
                                        when '*'
                                            # Exclude paralogs if all other organisms selected.
                                            query.where.push [ "homologues.homologue.organism.name", "ONE OF",
                                                homologueOrganisms = ( x for x in Organisms when x isnt @req.body['gene-organism'] )
                                            ]
                                        else
                                            query.where.push [
                                                "homologues.homologue.organism.name"
                                                "="
                                                homologueOrganismName
                                            ]
                                            homologueOrganisms = [ homologueOrganismName ]

                                    mine.query query, (q) =>
                                        app.log.info q.toXML().blue
                                        q.rows (data) =>
                                            app.log.info "Reorganizing the rows".grey

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
                                                        if @req.body['dataset'] isnt '*'
                                                            results[id]['homologues'][org][@req.body['dataset']] = []
                                                        else
                                                            for dataSet in DB.dataSets
                                                                results[id]['homologues'][org][dataSet] = []

                                                # Push the homologue object.
                                                results[id]['homologues'][row[5]][row[6]].push
                                                    'primaryIdentifier': row[3]
                                                    'symbol':            row[4]

                                            app.log.info "Returning back the rows".grey

                                            @res.writeHead 200, "content-type": "application/json"
                                            @res.write JSON.stringify
                                                'query':   q.toXML()
                                                'results': results
                                            @res.end()
                        
                        when 'ERROR'
                            app.log.info body.message.red
                            @res.writeHead 500
                            @res.end()
                        when null
                            app.log.info body.error.red
                            @res.writeHead 500
                            @res.end()

                        else setTimeout checkJob, 1000

# Dataset summary.
app.router.path '/api/summary', ->
    @get ->
        app.log.info "Getting datasets summary"

        @req.connection.setTimeout 600000

        # Parse the server response.
        parse = (data) ->
            # Form the grid of data set organisms.
            dataSets = {} ; organisms = {}

            for [id, set, homoOrg] in data
                # Save the organism.
                organisms[homoOrg] ?= {}
                # Get us the dataset name.
                dataSets[set] = true

                if organisms[homoOrg][set]?
                    organisms[homoOrg][set] += 1
                else
                    organisms[homoOrg][set] = 1

            [organisms, dataSets]

        # Render the data.
        render = =>
            app.log.info 'Returning datasets summary'

            @res.writeHead 200, "content-type": "application/json"
            @res.write JSON.stringify DB.summary
            @res.end()

        # Make the server call.
        if not DB.summary?
            mine.query Queries.summary, (q) ->
                q.rows (data) ->
                    [organisms, dataSets] = parse data
                    DB.summary =
                        'organisms': organisms
                        'dataSets':  dataSets
                        'query':     q.toXML()
                        'stamp':     new Date()
                    
                    render()
        else
            render()

# Organism overlap.
app.router.path '/api/organism', ->
    @get ->
        app.log.info "Getting organism overlap"

        @req.connection.setTimeout 600000

        # Parse the server response records.
        parse = (records) ->
            grid = {}
            for gene in records
                geneOrganismName = gene.organism.name
                grid[geneOrganismName] ?= {}
                
                usedHomologues = [] # Keep track of homologues we have already included (do not include the same reference from diff set).
                for homologue in gene.homologues
                    homologueOrganismName = homologue.homologue.organism.name ; homologueId = homologue.homologue.objectId
                    # Do not count us.
                    if geneOrganismName isnt homologueOrganismName
                        # Have we not used it before?
                        if usedHomologues.indexOf(homologueId) < 0
                            # Init.
                            grid[geneOrganismName][homologueOrganismName] ?= 0
                            # +1
                            grid[geneOrganismName][homologueOrganismName] += 1
                            # Used...
                            usedHomologues.push homologueId

            # Count the number of organisms.
            size = 0 ; for org, v of grid then do -> size += 1

            [grid, size]

        # Render the data.
        render = =>
            app.log.info 'Returning organism overlap'

            @res.writeHead 200, "content-type": "application/json"
            @res.write JSON.stringify DB.organism
            @res.end()

        # Make the server call.
        if not DB.organism?
            mine.query Queries.organismOverlap, (q) ->
                q.records (data) ->
                    [organisms, size] = parse data
                    DB.organism =
                        'organisms': Organisms
                        'size':      size
                        'query':     q.toXML()
                        'stamp':     new Date()
                    
                    render()
        else
            render()

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