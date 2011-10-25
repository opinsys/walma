
express = require "express"
piler = require "piler"
logClients = require "./lib/clientlogger"

module.exports = (app, io) ->


  css = piler.createCSSManager()
  js = piler.createJSManager()


  clientFiles = __dirname + "/client"

  app.configure ->
    app.use express.static __dirname + "/public"

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
    js.addFile clientFiles + "/require.coffee"
    js.addFile clientFiles + "/vendor/require.js"
    js.addFile clientFiles + "/vendor/jquery.js"
    js.addFile clientFiles + "/vendor/async.js"
    js.addModule clientFiles + "/vendor/underscore.js"
    # js.addModule clientFiles + "/vendor/underscore.string.js"
    js.addModule clientFiles + "/vendor/backbone.js"
    js.addFile clientFiles + "/vendor/handlebars.js"
    js.addFile clientFiles + "/helpers.coffee"

    js.addFile clientFiles + "/inputs.coffee"
    js.addFile clientFiles + "/drawers.models.coffee"
    js.addFile clientFiles + "/drawers.views.coffee"
    js.addModule __dirname + "/shared/drawtools.coffee"
    js.addFile clientFiles + "/maindrawer.coffee"

    js.addFile "paint", clientFiles + "/main.coffee"
    js.addFile "frontpage", clientFiles + "/frontpage.coffee"


  app.configure "development", ->
    css.addFile "spec", clientFiles + "/vendor/jasmine/jasmine.css"

    js.addFile "spec", clientFiles + "/vendor/jasmine/jasmine.js"
    js.addFile "spec", clientFiles + "/vendor/jasmine/jasmine-html.js"
    js.addFile "spec", __dirname + "/spec/tools.spec.coffee"
    # js.addFile "spec", __dirname + "/spec/require.spec.coffee"
    js.addFile "spec", clientFiles + "/specrunner.js"

    app.get "/spec", (req, res) ->
      res.render "spec.jade",
        layout: false


  app.listen 1337
