console.log "walma-remote-start"

server = window.location.protocol + "//" + window.location.host

socket = io.connect().of("/remote-start")
 
socket.on "open-browser", (opts) ->
  console.log "Open new window"
  window.open server + opts.url

currentRemoteKey = ""
newRemoteKey = ""

$ ->
  $("form input[type='submit']").click ->
    $(this).val('Change remote key')
    if currentRemoteKey isnt ""
      socket.emit "leave-desktop", { remote_key: currentRemoteKey }
    newRemoteKey = $('[name=remoteKey]').val()
    socket.emit "join-desktop", { remote_key: newRemoteKey }
    # Set client resolution
    socket.emit "set resolution",
      width: $(window).width(),
      height: $(window).height()
    currentRemoteKey = newRemoteKey
    false
  