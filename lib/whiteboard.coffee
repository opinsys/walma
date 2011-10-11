
express = require "express"
piler = require "piler"
_  = require 'underscore'
_.mixin require 'underscore.string'


logClients = require "./clientlogger"

css = piler.createCSSManager()
js = piler.createJSManager()
app = express.createServer()

io = require('socket.io').listen app

clientFiles = __dirname + "/../client"

app.configure ->
  app.use express.static __dirname + "/../public"

  js.bind app
  css.bind app


app.configure "development", ->
  js.addFile clientFiles + "/remotelogger.coffee"
  js.liveUpdate css, io
  logClients io

app.configure ->

  css.addFile clientFiles + "/stylesheets/style.styl"

  js.addUrl "/socket.io/socket.io.js"
  js.addFile clientFiles + "/vendor/jquery.js"
  js.addFile clientFiles + "/vendor/async.js"
  js.addFile clientFiles + "/vendor/underscore.js"
  js.addFile clientFiles + "/vendor/underscore.string.js"
  js.addFile clientFiles + "/vendor/backbone.js"

  js.addFile clientFiles + "/helpers.coffee"
  js.addFile clientFiles + "/drawers.coffee"
  js.addFile clientFiles + "/drawers.tools.coffee"
  js.addFile clientFiles + "/drawers.models.coffee"
  js.addFile clientFiles + "/drawers.views.coffee"
  js.addFile clientFiles + "/main.coffee"


# Drawing history "database"
db = {}

app.get "/", (req, res) ->

  rooms = _.map db, (room, name) ->
    return {} unless room
    console.log "mapping #{ room }"
    name: name
    historySize: room.history?.length

  res.render "index.jade",
    rooms: rooms


app.get "/:room", (req, res) ->
  res.render "paint.jade"

app.listen 1337



sockets = io.of "/drawer"
sockets.on "connection", (socket) ->
  socket.on "join", (room) ->

    # Send history to the new client
    socket.emit "start", db[room] ?= []

    socket.join room

    socket.on "draw", (draw) ->
      # got new shape from some client

      # Append change to the history
      db[room].push draw

      # console.log "got #{ room }", JSON.stringify draw
      # Send new shape to all clients in the room
      socket.broadcast.to(room).emit "draw", draw





