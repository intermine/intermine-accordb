#!/usr/bin/env coffee

express =  require 'express'
eco     =  require 'eco'
https =    require 'https'
fs =       require 'fs'
socketio = require 'socket.io'

# -------------------------------------------------------------------
# Express and Socket.IO config.
app = express()
server = app.listen 4000
io = socketio.listen server

exports.app = app
exports.io = io

console.log "Express server listening to port 4000"

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
        'dumpExceptions': true
        'showStack':      true

app.configure 'production', ->
    app.use express.errorHandler()