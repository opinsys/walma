server = window.location.protocol + "//" + window.location.host

socket = io.connect().of("/remote-start")
 
socket.on "open-browser", (opts) ->
  window.open server + opts.url

currentRemoteKey = ""

$ ->
  buttons = $("form input[type='submit']")

  buttons.bind "tap", ->
    $(this).click()

  $(".startProjector input[type=submit]").click ->
    newRemoteKey = $('.startProjector [name=remoteKey]').val()
    e = $('.projectorInfo')
    e.css 'top', $(this).position().top + $(this).height() - e.height()
    $('.projectorInfo input[name=remoteKey]').val(newRemoteKey)
    $('.cameraId').text(newRemoteKey).html
    e.show()
    $('.pageOverlay').show()
    startListening newRemoteKey
    false

  $(".projectorInfo input[type=submit]").click ->
    newRemoteKey = $('.projectorInfo input[name=remoteKey]').val()
    $('.cameraId').text(newRemoteKey).html
    startListening newRemoteKey
    false

  $(".projectorInfo a.close").click ->
    if currentRemoteKey isnt ""
      socket.emit "leave-desktop", { remote_key: currentRemoteKey }
    currentRemoteKey = ""
    $('.startProjector [name=remoteKey]').val("")
    $('.projectorInfo').hide(500)
    $('.pageOverlay').hide()
    false

startListening = (newRemoteKey) ->
  if currentRemoteKey isnt ""
    socket.emit "leave-desktop", { remote_key: currentRemoteKey }
  socket.emit "join-desktop", { remote_key: newRemoteKey }
  # Set client resolution
  socket.emit "set resolution",
    width: $(window).width(),
    height: $(window).height()
  currentRemoteKey = newRemoteKey

