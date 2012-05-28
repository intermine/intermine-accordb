express = require 'express'
eco     = require 'eco'
https =   require 'https'
fs =      require 'fs'
imjs =    require 'imjs'

# Internal storage.
DB = {}

# Express.
app = express.createServer()

app.configure ->
    app.use express.logger()
    app.use express.bodyParser()

    app.set 'view engine', 'eco'
    app.set 'views', './templates'

    # Register a custom .eco compiler.
    app.engine 'eco', (path, options, callback) ->
        fs.readFile "./#{path}", "utf8", (err, str) ->
            callback eco.render str, options

    app.use express.static('./public')

app.configure 'development', ->
    app.use express.errorHandler
        dumpExceptions: true
        showStack:      true

app.configure 'production', ->
    app.use express.errorHandler()

# Redirect to upload from index.
app.get '/', (req, res) -> res.redirect '/upload'

# Show gene upload.
app.get '/upload', (req, res) ->
    res.render 'upload',
        'data': []
    , (html) -> res.send html, 'Content-Type': 'text/html', 200

# Show dataset summary.
app.get '/summary', (req, res) ->

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
    render = () ->
        res.render 'summary', DB.summary
        , (html) -> res.send html, 'Content-Type': 'text/html', 200

    # Make the server call.
    if not DB.summary?
        flymine = new imjs.Service root: "beta.flymine.org/beta"
        query =
            from: "Gene"
            select: [
                "primaryIdentifier"
                "homologues.dataSets.name"
                "homologues.homologue.organism.name"
            ]
            where:
                symbol:
                    contains: "theta"
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

# Show organism overlap.
app.get '/organism', (req, res) ->

    # Parse the server response records.
    parse = (records) ->
        grid = {}
        for gene in records
            grid[gene.organism.name] ?= {}
            
            for homologue in gene.homologues
                grid[gene.organism.name][homologue.homologue.organism.name] ?= 0
                grid[gene.organism.name][homologue.homologue.organism.name] += 1

        console.log grid
        grid

    # Render the data.
    render = () ->
        res.render 'organism', DB.organism
        , (html) -> res.send html, 'Content-Type': 'text/html', 200

    # Make the server call.
    if not DB.organism?
        flymine = new imjs.Service root: "beta.flymine.org/beta"
        organisms = [
            'Drosophila melanogaster'
            'Anopheles gambiae'
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
                [ "symbol", '=', 'CDC27' ]
            ]

        flymine.query query, (q) ->
            q.records (data) ->
                DB.organism =
                    'organisms': parse data
                    'query':     q.toXML()
                    'stamp':     new Date()
                
                render()
    else
        render()

# Start server.
app.listen 4000
console.log "Express server listening to port 4000"