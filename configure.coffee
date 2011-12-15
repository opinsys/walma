fs = require "fs"
express = require "express"
piler = require "piler"
logClients = require "./lib/clientlogger"

config = JSON.parse fs.readFileSync __dirname + "/config.json"

dbTools = require "./db"

dbTools.open config


exports.setUp = (app, io) ->


  css = piler.createCSSManager()
  js = piler.createJSManager()


  clientFiles = __dirname + "/client"

  app.configure ->
    app.use express.static __dirname + "/public"
    app.use express.bodyParser
      uploadDir: "/tmp"

    js.bind app
    css.bind app


  app.configure "development", ->
    js.addFile clientFiles + "/remotelogger.coffee"
    js.liveUpdate css, io
    logClients io

  app.configure ->

    css.addFile "main", clientFiles + "/stylesheets/reset.css"
    css.addFile "main", clientFiles + "/stylesheets/style.styl"
    css.addFile clientFiles + "/vendor/jquery.notice/jquery.notice.css"

    js.addUrl "/socket.io/socket.io.js"
    js.addFile clientFiles + "/require.coffee"
    js.addFile clientFiles + "/vendor/modernizr.js"
    js.addFile clientFiles + "/vendor/require.js"
    js.addFile clientFiles + "/vendor/jquery.js"
    js.addFile clientFiles + "/vendor/jquery.notice/jquery.notice.js"
    js.addFile clientFiles + "/vendor/async.js"
    js.addModule clientFiles + "/vendor/underscore.js"
    # js.addModule clientFiles + "/vendor/underscore.string.js"
    js.addModule clientFiles + "/vendor/backbone.js"
    js.addFile clientFiles + "/vendor/handlebars.js"
    js.addFile clientFiles + "/helpers.coffee"

    js.addFile clientFiles + "/drawarea.coffee"
    js.addFile clientFiles + "/inputs.coffee"
    js.addFile clientFiles + "/taggingrouter.coffee"
    js.addFile clientFiles + "/drawers.models.coffee"
    js.addFile clientFiles + "/unsavedwarning.views.coffee"
    js.addFile clientFiles + "/welcome.views.coffee"
    js.addFile clientFiles + "/debug.views.coffee"
    js.addFile clientFiles + "/roominfo.views.coffee"
    js.addFile clientFiles + "/miscmenu.views.coffee"
    js.addFile clientFiles + "/lightbox.coffee"
    js.addFile clientFiles + "/notification.coffee"
    js.addFile clientFiles + "/toolmenu.coffee"
    js.addFile clientFiles + "/background.coffee"
    js.addModule __dirname + "/shared/drawtools.coffee"
    js.addFile clientFiles + "/maindrawer.coffee"

    js.addFile "paint", clientFiles + "/main.coffee"
    js.addFile "frontpage", clientFiles + "/frontpage.coffee"



  app.listen config.listenPort, ->
    console.log "Walma is now listening on port #{ config.listenPort }"

