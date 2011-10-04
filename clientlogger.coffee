
# Tool for printing console.log messages from the browser.
# Usefull for devices that does not show the console output.

module.exports = (io) ->
  console.log "Activating client logger"
  debug = io.of "/debug"
  debug.on "connection", (socket) ->
    socket.on "console.log", (msg) ->
      console.log "browser:", msg
