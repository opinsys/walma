
express = require "express"
piler = require "piler"
logClients = require "./clientlogger"

css = piler.createCSSManager()
js = piler.createJSManager()
app = express.createServer()

io = require('socket.io').listen app

js.bind app
css.bind app

clientFiles = __dirname + "/../client"

app.configure "development", ->
  js.addFile clientFiles + "/remotelogger.coffee"
  js.liveUpdate css, io
  logClients io


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


main = (req, res) ->
  res.render "index.jade"



app.get "/", main
app.get "/:room", main


app.listen 1337


# Drawing history "database"
db = {}

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





