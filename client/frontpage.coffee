server = window.location.protocol + "//" + window.location.host

socket = io.connect().of("/remote-start")
 
socket.on "open-browser", (opts) ->
  window.open server + opts.url

currentRemoteKey = ""

$ ->
  blank_camera_id = "Camera id can't be blank"

  # Projector form is hidden. Show only if projector parameter is set.
  # This code shoubld be deleted when Projector feature published
  if projector
    $(".startProjector").show()
  else
    footer = $('.footer')
    footer.css('text-align', 'center')
    footer.css('padding-top', '10px')
    footer.css('position', 'absolute')
    footer.css('bottom', '1em')

  buttons = $("form input[type='submit']")

  buttons.bind "tap", ->
    $(this).click()

  $(".startProjector input[type=submit]").click ->
    newRemoteKey = $('.startProjector [name=remoteKey]').val()
    if newRemoteKey is ""
      $('.error').text(blank_camera_id)
      return false
    e = $('.projectorInfo')
    e.css 'top', $(this).position().top + $(this).height() - e.height()
    $('.projectorInfo input[name=remoteKey]').val(newRemoteKey)
    $('.cameraId').text(newRemoteKey)
    e.show()
    $('.pageOverlay').show()
    startListening newRemoteKey
    false

  $(".projectorInfo input[type=submit]").click ->
    newRemoteKey = $('.projectorInfo input[name=remoteKey]').val()
    if newRemoteKey is ""
      $('.error').text(blank_camera_id)
      return false
    $('.cameraId').text(newRemoteKey)
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

