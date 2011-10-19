fs = require "fs"
express = require "express"
_  = require 'underscore'
_.mixin require 'underscore.string'

{Db, Connection, Server} = require "mongodb"

app = express.createServer()
io = require('socket.io').listen app

{Drawing} = require "./lib/drawmodel"
{Client} = require "./lib/client"

db = new Db('whiteboard', new Server("localhost", Connection.DEFAULT_PORT))
db.open (err) ->
  if err
    console.log "Could not open the database", err.trace
    process.exit(1)

  db.collection "drawings", (err, collection) ->
    Drawing.collection = collection
    console.log "got collection"



require("./configure") app, io


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

rooms = {}

sockets = io.of "/drawer"
sockets.on "connection", (socket) ->


  socket.on "join", (opts) ->
    roomName = opts.room

    # Send history to the new client
    if not room = rooms[roomName]
      console.log "Creating new room"
      rooms[roomName] = room = new Drawing roomName

    room.addClient client = new Client socket, opts

    client.on "draw", (draw) ->
      # got new shape from some client

      room.addDraw draw

      # Send new shape to all clients in the room
      socket.broadcast.to(roomName).emit "draw", draw





