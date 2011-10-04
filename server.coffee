

express = require "express"

app = express.createServer()

app.get "/", (req, res) ->
  res.send "Hello"

app.listen 1337
