#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
request  = require 'request'
imjs     = require 'imjs'
urlib    = require 'url'
fs       = require 'fs'
qs       = require 'querystring'

# -------------------------------------------------------------------
# Config filters and start.

app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        connect.static __dirname + '/public'
    ]

app.start 4000, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}".green

# Internal storage.
DB = {}

# Mine connection.
mine = new imjs.Service root: "http://beta.flymine.org/beta"

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
            "id",
            "symbol",
            "organism.name",
            "homologues.homologue.id",
            "homologues.homologue.symbol",
            "homologues.homologue.organism.name",
            "homologues.dataSets.name"
        ]
        where: [
            # Hardcode constrain on the gene organism.
            [ "organism.name", "=", 'Drosophila melanogaster' ]
        ,
            # Exclude paralogs.
            [ "homologues.homologue.organism.name", "ONE OF", [
                    'Caenorhabditis elegans',
                    'Danio rerio',
                    'Homo sapiens',
                    'Mus musculus',
                    'Rattus norvegicus',
                    'Saccharomyces cerevisiae'
                ]
            ]
        ]
        # Order by gene id > homologue organism > homologue dataset.
        sortOrder: [
            path: 'id'
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
        #where: [
        #   [ "symbol", '=', 'CDC*' ]
        #]
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
        #,
            #[ "homologues.homologue.symbol", "=", "CDC*" ]
        ]

# -------------------------------------------------------------------
# Resolve identifiers and show counts in datasets.
app.router.path '/api/upload', ->
    @post ->
        app.log.info "Resolve gene symbols into homologues"

        app.log.info "Posting identifiers".grey

        request
            'uri':    "http://beta.flymine.org/beta/service/ids"
            'method': "POST"
            'json':
                'identifiers': [ '128up', '18w', 'ACXA' ]
                'type':        'Gene'
        , (err, res, body) =>
            throw err if err

            job = body.uid
            do checkJob = =>
                app.log.info "Checking job #{job}".grey
                request
                    'uri':    "http://beta.flymine.org/beta/service/ids/#{job}/status"
                    'method': "GET"
                , (err, res, body) =>
                    throw err if err

                    body = JSON.parse(body)

                    app.log.info "Job #{job} says #{body.status}".grey

                    switch body.status
                        when 'SUCCESS'
                            app.log.info "Getting result of job #{job}".grey

                            request
                                'uri':    "http://beta.flymine.org/beta/service/ids/#{job}/result"
                                'method': "GET"
                            , (err, res, body) =>
                                throw err if err

                                ids = (key for key, value of JSON.parse(body).results)

                                app.log.info "Getting homologues for genes".grey
                                
                                # Identifiers received through resolution service.
                                query = Queries.homologuesForGenes
                                query.where.push [ "id", "ONE OF", ids ]

                                mine.query query, (q) =>
                                    app.log.info q.toXML().blue
                                    q.rows (data) =>
                                        reorg = (data) =>
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
                                                        'homologues':
                                                            'Caenorhabditis elegans': {}
                                                            'Danio rerio': {}
                                                            'Homo sapiens': {}
                                                            'Mus musculus': {}
                                                            'Rattus norvegicus': {}
                                                            'Saccharomyces cerevisiae': {}
                                                    # Fill it up with dataset arrays per homologue organism.
                                                    for org, v of results[id]['homologues']
                                                        for dataSet in DB.dataSets
                                                            results[id]['homologues'][org][dataSet] = []

                                                # Push the homologue object.
                                                results[id]['homologues'][row[5]][row[6]].push
                                                    'id':     row[3]
                                                    'symbol': row[4]

                                            app.log.info "Returning back the rows".grey

                                            @res.writeHead 200, "content-type": "application/json"
                                            @res.write JSON.stringify results
                                            @res.end()

                                        # Do we know which datasets we will be using?
                                        if DB.dataSets? then reorg data
                                        else
                                            app.log.info "Fetching homologue datasets".grey
                                            mine.query Queries.homologueDataSets, (q) =>
                                                q.rows (dataSets) =>
                                                    DB.dataSets = (x[0] for x in dataSets)
                                                    reorg data
                        
                        when 'ERROR'
                            throw body.message.red

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