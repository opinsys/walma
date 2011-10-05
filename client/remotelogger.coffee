
# Send console.log messages to the server for debugging


debug = io.connect().of("/debug")

console.log "Replacing console.log with remote logger"

debug.on "disconnect", ->
  console.log "Server disconnected. Reloading in 1s"
  window.location.reload()

if not window.console?.log?
  window.console =
    log: ->

console_ = console
origLog = (args) ->
  console_.log.apply console_, args

window.console =
  log: (args...) ->
    origLog args
    if $?
      $("#log").append args.join(", ") + "\n"

    # socket.io does the real serialization. We just remove the parts it cannot
    # serialized
    serialized = for part in args
      try
        JSON.stringify part
        part 
      catch e
        "(non json: #{ part })"

    debug.emit "console.log",
      agent: navigator.userAgent
      args: serialized

console.log "clien logger connected"

