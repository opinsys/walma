fs = require "fs"
express = require "express"
_  = require 'underscore'
_.mixin require 'underscore.string'


app = express.createServer()
io = require('socket.io').listen app
io.set "log level", 0

{Drawing} = require "./lib/drawmodel"
{Client} = require "./lib/client"

generateUniqueName = require "./lib/namegenerator"
urlshortener = require "./lib/urlshortener"


db = require("./db").open()

require("./configure") app, io


app.get "/", (req, res) ->
  res.send '''
  <h1>Whiteboard</h1>
  <p>Room:</p>
  <form action="/" method="post" accept-charset="utf-8">
  <p><input type="text" name="roomName" /></p>
  <p><input type="submit" value="Go"></p>
  <p><input type="submit" name="generate" value="Generate new"></p>
  </form>
  '''

app.post "/", (req, res) ->

  if req.body.generate
    generateUniqueName "main"
      , (prefix, num) ->
        urlshortener.encode num
      , (err, roomName) ->
        throw err if err
        res.setHeader "Location", "/" + roomName
        res.send 302
  else
    res.setHeader "Location", "/" + req.body.roomName
    res.send 302


app.get "/bootstrap", (req, res) ->
  res.render "bootstrap.jade"

withRoom = (fn) -> (req, res) ->
  room = new Drawing req.params.room
  room.fetch (err) ->
    throw err if err
    fn.call this, req, res, room

# TODO: Proper 404, do not thow error on missing images
app.get "/:room/bg", withRoom (req, res, room) ->
  res.contentType "image/png"
  room.getImage "background", (err, data) ->
    console.log err
    throw err if err
    res.send data

app.get "/:room/published.png", withRoom (req, res, room) ->
  res.contentType "image/png"
  room.getImage "publishedImage", (err, data) ->
    throw err if err
    res.send data



app.post "/api/create", (req, res) ->

  generateUniqueName "screenshot"
    , (prefix, num) ->
      "#{ prefix }-#{ num }"
    , (err, roomName) ->
      throw err if err
      room = new Drawing roomName, 1
      room.fetch ->
        room.saveImage "background", new Buffer(req.body.image, "base64"), (err) ->
          throw err if err
          res.json url: "/#{ roomName }"



app.get "/:room", (req, res) ->
  res.render "paint.jade"


app.get "/:room/bitmap/:pos", (req, res) ->
  res.header('Content-Type', 'image/png')

  room = new Drawing req.params.room
  room.getCache req.params.pos, (err, data) ->
    throw err if err
    res.send data


rooms = {}

sockets = io.of "/drawer"
sockets.on "connection", (socket) ->


  socket.on "join", (opts) ->
    roomName = opts.room

    room = rooms[roomName]
    if not room
      room = rooms[roomName] = new Drawing roomName

      console.log "new room", room.toString()
      room.on "empty", ->
        console.log "Empty room #{ room.toString() }. Removing reference."
        delete rooms[roomName]
        room.removeAllListeners()

    client = new Client
      socket: socket
      model: room
      userAgent: opts.userAgent
      id: opts.id
    console.log "added client to #{ room.toString() }"


    client.join()

