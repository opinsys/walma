
# Send console.log messages to the server for debugging


debug = io.connect().of("/debug")

console.log "Replacing console.log with remote logger"


debug.on "disconnect", ->
  console.log "Server disconnected. Reloading in 1s"
  window.location.reload()


origLog = console.log
window.console =
  log: (args...) ->
    origLog.apply this, args
    debug.emit "console.log", args

