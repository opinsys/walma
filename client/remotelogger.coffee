
# Send console.log messages to the server for debugging


debug = io.connect "/debug"

console.log "Replacing console.log with remote logger"

origLog = console.log
window.console =
  log: (args...) ->
    origLog.apply this, args
    debug.emit "console.log", args

