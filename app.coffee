express = require 'express'
eco     = require 'eco'
https =   require 'https'
fs =      require 'fs'
imjs =    require 'imjs'

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
    res.render 'summary',
        'data': []
    , (html) -> res.send html, 'Content-Type': 'text/html', 200

# Show organism overlap.
app.get '/organism', (req, res) ->
    res.render 'organism',
        'data': []
    , (html) -> res.send html, 'Content-Type': 'text/html', 200

# Start server.
app.listen 4000
console.log "Express server listening to port 4000"