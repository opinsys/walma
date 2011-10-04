
express = require "express"
pile = require "pile"

css = pile.createCSSManager()
js = pile.createJSManager()
app = express.createServer()

app.configure  ->
  js.bind app
  css.bind app

  css.addFile __dirname + "/stylesheets/style.styl"

  js.addFile __dirname + "/client/vendor/jquery.js"
  js.addFile __dirname + "/client/vendor/underscore.js"
  js.addFile __dirname + "/client/vendor/underscore.string.js"
  js.addFile __dirname + "/client/vendor/backbone.js"

  js.addFile __dirname + "/client/helpers.coffee"
  js.addFile __dirname + "/client/views.coffee"
  js.addFile __dirname + "/client/main.coffee"

app.configure "development", ->
  js.liveUpdate css

app.get "/", (req, res) ->
  res.render "index.jade"

app.listen 1337



