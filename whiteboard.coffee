fs = require "fs"
express = require "express"
_  = require 'underscore'
_.mixin require 'underscore.string'


app = express.createServer()
io = require('socket.io').listen app

{Drawing} = require "./lib/drawmodel"
{Client} = require "./lib/client"

generateName = require "./lib/namegenerator"


db = require("./db").open()

require("./configure") app, io


app.post "/", (req, res) ->
  res.redirect "/" + req.body.roomName

app.get "/", (req, res) ->
  res.send '''
  <h1>Whiteboard</h1>
  <p>Room:</p>
  <form action="" method="post" accept-charset="utf-8">
  <p><input type="text" name="roomName" /></p>
  <p><input type="submit" value="Go"></p>
  </form>
  '''
  return

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


app.get "/bootstrap", (req, res) ->
  res.render "bootstrap.jade"

app.get "/:room/bg", (req, res) ->
  # res.header('Content-Type', 'image/png')
  res.contentType "image/png"
  room = new Drawing req.params.room
  room.getBackground (err, data) ->
    throw err if err
    res.send data






app.post "/api/create", (req, res) ->
  console.log "GOTpost"
  generateName (err, roomName) ->
    throw err if err
    room = new Drawing roomName
    room.fetch ->
      room.setBackground new Buffer(req.body.image, "base64"), (err) ->
        throw err if err
        res.json url: "/#{ roomName }"


app.get "/:room", (req, res) ->
  res.render "paint.jade"

app.get "/:room/bitmap/:pos", (req, res) ->
  res.header('Content-Type', 'image/png')

  room = new Drawing req.params.room
  room.getCache req.params.pos, (err, data) ->
    throw err if err
    [__, pngData] = data.split ","
    res.send new Buffer(pngData, "base64")




rooms = {}

sockets = io.of "/drawer"
sockets.on "connection", (socket) ->


  socket.on "join", (opts) ->
    roomName = opts.room

    # Send history to the new client
    if not room = rooms[roomName]
      console.log "Creating new room"
      rooms[roomName] = room = new Drawing roomName

    console.log "Adding client"
    client = new Client
      socket: socket
      model: room

    client.join()



    client.on "draw", (draw) ->
      # got new shape from some client

      # Send new shape to all clients in the room
      socket.broadcast.to(roomName).emit "draw", draw





