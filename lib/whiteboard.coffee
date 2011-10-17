fs = require "fs"
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

  css.addFile "main", clientFiles + "/stylesheets/reset.css"
  css.addFile "main", clientFiles + "/stylesheets/style.styl"

  js.addUrl "/socket.io/socket.io.js"
  js.addFile clientFiles + "/vendor/jquery.js"
  js.addFile clientFiles + "/vendor/async.js"
  js.addFile clientFiles + "/vendor/underscore.js"
  js.addFile clientFiles + "/vendor/underscore.string.js"
  js.addFile clientFiles + "/vendor/backbone.js"
  js.addFile clientFiles + "/vendor/handlebars.js"
  js.addFile clientFiles + "/helpers.coffee"

  js.addFile clientFiles + "/drawers.coffee"
  js.addFile clientFiles + "/drawers.tools.coffee"
  js.addFile clientFiles + "/drawers.models.coffee"
  js.addFile clientFiles + "/drawers.views.coffee"

  js.addFile "paint", clientFiles + "/main.coffee"
  js.addFile "frontpage", clientFiles + "/frontpage.coffee"


app.configure "development", ->
  css.addFile "spec", clientFiles + "/vendor/jasmine/jasmine.css"

  js.addFile "spec", clientFiles + "/vendor/jasmine/jasmine.js"
  js.addFile "spec", clientFiles + "/vendor/jasmine/jasmine-html.js"
  js.addFile "spec", __dirname + "/../spec/tools.spec.coffee"
  js.addFile "spec", clientFiles + "/specrunner.js"

  app.get "/spec", (req, res) ->
    res.render "spec.jade",
      layout: false



# Ghetto database
#
dbFile = __dirname + "/../db.json"
try
  db = JSON.parse fs.readFileSync dbFile
  console.log "loaded db from", dbFile
catch e
  console.log "could not load db", e
  db = {}

dbDirty = false
setInterval ->
  return unless dbDirty
  fs.writeFile dbFile, JSON.stringify(db), (err) ->
    throw err if err
    dbDirty = false
    console.log "saved db to", dbFile
, 5000



# db.bug = (JSON.parse fs.readFileSync __dirname + "/bug.json")

app.get "/", (req, res) ->

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

app.listen 1337



sockets = io.of "/drawer"
sockets.on "connection", (socket) ->
  socket.on "join", (room) ->

    # Send history to the new client
    socket.emit "start", db[room] ?= []

    socket.join room

    socket.on "draw", (draw) ->
      dbDirty = true
      # got new shape from some client

      # Append change to the history
      db[room].push draw

      # console.log "got #{ room }", JSON.stringify draw
      # Send new shape to all clients in the room
      socket.broadcast.to(room).emit "draw", draw





