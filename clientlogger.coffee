useragent = require 'useragent'
# Tool for printing console.log messages from the browser.
# Usefull for devices that does not show the console output.

module.exports = (io) ->
  console.log "Activating client logger"
  debug = io.of "/debug"
  debug.on "connection", (socket) ->
    socket.on "console.log", (msg) ->
      msg.args.unshift  useragent.parse(msg.agent).toAgent() + ":"
      console.log.apply console, msg.args
