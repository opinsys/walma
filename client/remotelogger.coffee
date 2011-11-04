
# Send console.log messages to the server for debugging


debug = io.connect().of("/debug")

console.log "Replacing console.log with remote logger"

debug.on "disconnect", ->
  console.log "Server disconnected. Reloading in 1s"
  window.location.reload()

# First make sure that we have some logging tool.
if not window.console?.log?
  window.console =
    log: ->


console_ = console
origLog = (args) -> console_.log.apply console_, args

# Wrap console.log so that we can also log messages to our development server.
# This is here because some crappy devices won't show to log otherwise.
window.console =
  log: (args...) ->
    origLog args

    # socket.io does the real serialization. We just remove the parts it cannot
    # serialize
    serialized = for part in args
      try
        JSON.stringify part
        # Can serialize this. Return the original for later serialization
        part 
      catch e
        "(non json: #{ part })"

    debug.emit "console.log",
      agent: navigator.userAgent
      args: serialized

console.log "client logger connected"
