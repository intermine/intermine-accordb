#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
#request  = require 'request'
imjs     = require 'imjs'
urlib    = require 'url'
fs       = require 'fs'

app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        connect.static __dirname + '/public'
    ]

app.start 4000, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}"

# Internal storage.
DB = {}

# FlyMine connection.
flymine = new imjs.Service root: "www.flymine.org/query"

# Resolve identifiers and show counts in datasets.
# app.router.path '/api/upload', ->
#     @post ->
#         app.log.info "Resolving identifiers"

#         request
#             'uri':    "www.flymine.org/query/service/ids"
#             'method': "POST"
#             'json':
#                 'identifiers': @req.body.identifiers.split(' ')
#                 'type':        'Gene'
#         , (err, res, body) =>
#             throw err if err
#             console.log res, body

#             """
#             query =
#                 from: "Gene"
#                 select: [ "identifier" ]
#                 where: [
#                    [ "homologues.homologue", 'LOOKUP', 'eve,zen' ]
#                    [ "organism.name", '=', @req.body.organism ]
#                 ]
#             """

#             @res.writeHead 200, "content-type": "application/json"
#             @res.write JSON.stringify 'necum': 'pico'
#             @res.end()

# Dataset summary.
app.router.path '/api/summary', ->
    @get ->
        app.log.info "Getting datasets summary"

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
            query =
                from: "Gene"
                select: [
                    "primaryIdentifier"
                    "homologues.dataSets.name"
                    "homologues.homologue.organism.name"
                ]
                where: [
                   [ "symbol", '=', '*beta*' ]
                ]
                sortOrder: [
                    path: 'homologues.homologue.organism.name'
                    direction: 'ASC'
                ]

            flymine.query query, (q) ->
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
            organisms = [
                'Caenorhabditis elegans'
                'Danio rerio'
                'Drosophila melanogaster'
                'Homo sapiens'
                'Mus musculus'
                'Rattus norvegicus'
                'Saccharomyces cerevisiae'
            ]
            query =
                from: "Gene"
                select: [ "organism.name", "homologues.homologue.organism.name", "id", "homologues.dataSets.name", "homologues.homologue.id" ]
                where: [
                    [ "organism.name", "ONE OF", organisms ]
                ,
                    [ "homologues.homologue.organism.name", "ONE OF", organisms ]
                ,
                    [ "symbol", '=', 'CDC*' ]
                ]

            flymine.query query, (q) ->
                q.records (data) ->
                    [organisms, size] = parse data
                    DB.organism =
                        'organisms': organisms
                        'size':      size
                        'query':     q.toXML()
                        'stamp':     new Date()
                    
                    render()
        else
            render()