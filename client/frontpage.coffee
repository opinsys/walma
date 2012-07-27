server = window.location.protocol + "//" + window.location.host

socket = io.connect().of("/remote-start")
 
socket.on "open-browser", (opts) ->
  window.open server + opts.url

currentCameraId = ""

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
    newCameraId = $('.startProjector [name=cameraId]').val()
    if newCameraId is ""
      $('.error').text(blank_camera_id)
      return false
    e = $('.projectorInfo')
    e.css 'top', $(this).position().top + $(this).height() - e.height()
    $('.projectorInfo input[name=cameraId]').val(newCameraId)
    $('.cameraId').text(newCameraId)
    e.show()
    $('.pageOverlay').show()
    startListening newCameraId
    false

  $(".projectorInfo input[type=submit]").click ->
    newCameraId = $('.projectorInfo input[name=cameraId]').val()
    if newCameraId is ""
      $('.error').text(blank_camera_id)
      return false
    $('.cameraId').text(newCameraId)
    startListening newCameraId
    false

  $(".projectorInfo a.close").click ->
    if currentCameraId isnt ""
      socket.emit "leave-desktop", { cameraId: currentCameraId }
    currentCameraId = ""
    $('.startProjector [name=cameraId]').val("")
    $('.projectorInfo').hide(500)
    $('.pageOverlay').hide()
    false
  
startListening = (newCameraId) ->
  $('.error').text("")
  if currentCameraId isnt ""
    socket.emit "leave-desktop", { cameraId: currentCameraId }
  socket.emit "join-desktop", { cameraId: newCameraId }
  # Set client resolution
  socket.emit "set resolution",
    width: $(window).width(),
    height: $(window).height()
  currentCameraId = newCameraId

