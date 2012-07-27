fs = require "fs"
gm = require "gm"
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


conf = require "./configure"

conf.setUp app, io


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
  projector = "false"
  if req.query["projector"]?
    projector = "true"

  res.render "index.jade",
    layout: false,
    locals: { projector: projector }
 
  # res.send '''
  # <h1>Whiteboard</h1>
  # <p>Room:</p>
  # <form action="/" method="post" accept-charset="utf-8">
  # <p><input type="text" name="roomName" /></p>
  # <p><input type="submit" value="Go"></p>
  # <p><input type="submit" name="generate" value="Generate new"></p>
  # </form>
  # '''

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


app.get "/multipart", (req, res) ->
  res.send """
    <!doctype html>
    <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8" />

      <title>POST</title>
    </head>
    <body>
      <form action="/api/create_multipart" method="post" enctype="multipart/form-data" accept-charset="utf-8">
       <input name=image type=file />
       <input type=submit value="Send image" />
      </form>
    </body>
  """

app.post "/api/create_multipart", (req, res) ->
  if req.body.cameraId?
    cameraId = req.body.cameraId
  else
    if req.body.remotekey?
      cameraId = req.body.remotekey
      console.log "Warning: client use old parameter name:", cameraId

  cameraId = req.body.cameraId or req.body.remote_key
  generateUniqueName "screenshot"
    , (prefix, num) ->
      "#{ prefix }-#{ num }"
    , (err, roomName) ->
      return res.send err.message if err
      room = new Drawing roomName
      room.fetch ->
        widths = []
        heights = []

        # Find clients minium resolutions
        for client in desktopSockets.clients(cameraId)
          client.get "resolution", (err, resolution) ->
            widths.push resolution.width
            heights.push resolution.height
        minWidth = Math.min.apply null, widths
        minHeight = Math.min.apply null, heights
     
        gm(req.files.image.path)
        .resize(minWidth, minHeight)
        .write req.files.image.path, ->

          fs.readFile req.files.image.path, (err, imageData) ->
            room.saveImage "background", imageData, (err) ->

              fs.unlink req.files.image.path, (err) ->
                if err
                  console.info "Failed to remove", req.files.image, err
  
              return res.send err.message if err
              console.log "Send open-browser message: ", cameraId
              desktopSockets.in(cameraId).emit("open-browser", { url: "/#{ roomName }" })
              res.json url: "/#{ roomName }"

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


desktopSockets = io.of "/remote-start"
desktopSockets.on "connection", (socket) ->
  socket.on "join-desktop", (opts) ->
    console.log "Joining: ", opts
    socket.join opts.cameraId
  socket.on "leave-desktop", (opts) ->
    console.log "Leaving: ", opts
    socket.leave opts.cameraId
  socket.on 'set resolution', (resolution) ->
    socket.set 'resolution', resolution, ->


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

