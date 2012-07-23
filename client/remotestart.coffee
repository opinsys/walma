console.log "walma-remote-start"

socket = io.connect().of("/remote-start")
 
socket.on "open-browser", (opts) ->
  console.log "Open new window"
  window.open "http://localhost" + opts.url

currentRemoteKey = ""
newRemoteKey = ""

$ ->
  $("form input[type='submit']").click ->
    $(this).val('Change remote key')
    if currentRemoteKey isnt ""
      socket.emit "leave-desktop", { remote_key: currentRemoteKey }
    newRemoteKey = $('[name=remoteKey]').val()
    socket.emit "join-desktop", { remote_key: newRemoteKey }
    currentRemoteKey = newRemoteKey
    false
  