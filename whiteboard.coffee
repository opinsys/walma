fs = require "fs"
express = require "express"
_  = require 'underscore'
_.mixin require 'underscore.string'
async = require "async"

app = express.createServer()
io = require('socket.io').listen app
io.set "log level", 0

{Drawing} = require "./lib/drawmodel"
{Client} = require "./lib/client"

generateUniqueName = require "./lib/namegenerator"
urlshortener = require "./lib/urlshortener"


db = require("./db").open()


require("./configure") app, io


# Simple in-process room manager. This needs work when we have to scale out one
# process
_rooms = {}
roomManager =
  get: (name, cb) ->
    room = _rooms[name]

    if not room
      room = _rooms[name] = new Drawing name
      room.on "empty", ->
        console.log "Empty room #{ room.toString() }. Removing reference."
        roomManager.delete name


    room.fetch (err, doc) ->
      return cb err if err
      cb null, room

  delete: (name) ->
    if room = _rooms[name]
      room.removeAllListeners()
      delete _rooms[name]




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

app.get "/delete", (req, res) ->
  Drawing.deleteExpiredRooms (err, count) ->
    if err
      console.log "Failed to delete", err
      res.send "Failed to delete", 500
    else
      res.send "deleted #{ count }", 200


app.get "/bootstrap", (req, res) ->
  res.render "bootstrap.jade"

withRoom = (fn) -> (req, res) ->
  roomManager.get req.params.room, (err, room) ->
    if err
      console.log "failed to open room #{ req.params.room }"
      req.send "Error opening room", 500
    else
      fn.call this, req, res, room


app.get "/:room/bg", withRoom (req, res, room) ->
  res.contentType "image/png"
  room.getImage "background", (err, data) ->
    if err
      console.log "Could not find backgrond for #{ room.name }", err
      res.send "not found", 404
    else
      res.send data

app.get "/:room/published.png", withRoom (req, res, room) ->
  res.contentType "image/png"
  room.getImage "publishedImage", (err, data) ->
    if err
      console.log "Could not find published image for #{ room.name }", err
      res.send "not found", 404
    else
      res.send data



app.post "/api/create", (req, res) ->
  generateUniqueName "screenshot"
    , (prefix, num) ->
      "#{ prefix }-#{ num }"
    , (err, roomName) ->
      throw err if err
      room = new Drawing roomName
      room.fetch ->
        room.saveImage "background", new Buffer(req.body.image, "base64"), (err) ->
          throw err if err
          res.json url: "/#{ roomName }"


# Epic dataURL parser. Returns base64 encoded PNG
parseDataURL = (dataURL) ->
  base64data = dataURL.split(",")[1]
  new Buffer(base64data, "base64")







imageToBuffer = (req, cb) ->

  if req.files.image
    fs.readFile req.files.image.path, (err, data) ->
      return cb err if err
      fs.unlink req.files.image.path, (err) ->
        return cb err if err
        cb null, data
  else
    base64data = parseDataURL req.body.image
    cb null, new Buffer(base64data, "base64")

app.post "/:room/image", withRoom (req, res, room) ->

  imageResponse = (err) ->
    if err
      console.log msg = "Failed to save image", err
      res.send msg, 500
    else
      console.log "image saved ok"
      res.send "ok"

  imageToBuffer req, (err, data) ->
    return imageResponse err if err

    if req.body.type is "background"
      room.saveImage "background", data, imageResponse
    else if req.body.type is "cache"
      room.setCache req.body.drawCount, data, imageResponse
    else
      imageResponse "Unknown image type #{ req.body.type }"









app.get "/:room", (req, res) ->
  res.render "paint.jade"


app.get "/:room/bitmap/:pos", (req, res) ->
  res.header('Content-Type', 'image/png')

  room = new Drawing req.params.room
  room.getCache req.params.pos, (err, data) ->
    if err
      res.send 404
    else
      res.send data



sockets = io.of "/drawer"
sockets.on "connection", (socket) ->


  socket.on "join", (opts) ->
    roomName = opts.room
    roomManager.get opts.room, (err, room) ->
      if err
        console.log "ERROR: could not open room #{ opts.room }", err
        return

      client = new Client
        socket: socket
        model: room
        userAgent: opts.userAgent
        id: opts.id

      console.log "added client to #{ room.toString() }"


      client.join()

