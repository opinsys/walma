fs = require "fs"
express = require "express"
_  = require 'underscore'
_.mixin require 'underscore.string'

app = express.createServer()
io = require('socket.io').listen app

require("./configure") app, io


# Ghetto database
#
dbFile = __dirname + "/db.json"
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





