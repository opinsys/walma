fs = require "fs"
express = require "express"
_  = require 'underscore'
_.mixin require 'underscore.string'

{Db, Connection, Server} = require "mongodb"

app = express.createServer()
io = require('socket.io').listen app


{Drawing} = require "./lib/drawmodel"

db = new Db('whiteboard', new Server("localhost", Connection.DEFAULT_PORT))
db.open (err) ->
  if err
    console.log "Could not open the database", err.trace
    process.exit(1)

  db.collection "drawings", (err, collection) ->
    Drawing.collection = collection
    console.log "got collection"

# db.collection "drawings", (err, collection) ->
#   return console.log err if err
#   Drawing.collection = collection



require("./configure") app, io
rooms = {}


app.get "/", (req, res) ->

  # TODO:
  rooms = _.map db, (history, name) ->
    return {} unless history
    name: name
    historySize:  _.reduce(history, (memo, draw) ->
      return memo unless draw?.shape?.moves
      memo + draw.shape.moves.length
    , 0)

  res.render "index.jade",
    rooms: rooms


app.get "/:room", (req, res) ->
  res.render "paint.jade"



cachers = {}


sockets = io.of "/drawer"
sockets.on "connection", (socket) ->

  socket.on "cacher", (id) ->
    console.log "I #{ id } can cache"
    cachers[id] =
      jobs: []
      socket: socket

  socket.on "join", (roomName) ->

    # Send history to the new client
    if not room = rooms[roomName]
      rooms[roomName] = room = new Drawing roomName

    room.fetch (err, doc) ->
      if err
        console.log "Error when fetching room #{ roomName }", err
      else
        socket.emit "start", doc.history
        socket.join roomName

    socket.on "draw", (draw) ->
      # got new shape from some client

      # Append change to the history
      room.addDraw draw

      # Send new shape to all clients in the room
      socket.broadcast.to(roomName).emit "draw", draw





