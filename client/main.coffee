
PWB = NS "PWB"

{DrawArea} = PWB.drawarea
{Background} = PWB.background

{drawers} = NS "PWB"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"
{Notification} = NS "PWB.notification"
helpers = NS "PWB.helpers"

maindrawer = NS "PWB.maindrawer"

Backbone = require "backbone"

socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window
if not hasTouch and typeof DocumentTouch isnt "undefined"
  hasTouch = document instanceof DocumentTouch



$ ->
  $(document).scroll (e) ->
    console.log "SCRolling"
    false

  $("body").bind "touchmove", (e) -> e.preventDefault()


  [__, roomName, position] = window.location.pathname.split("/")
  toolSettings = new models.ToolSettings

  socket = io.connect().of("/drawer")

  roomModel = new models.RoomModel
    socket: socket

  roomModel.set
    roomName: roomName
    position: parseInt position, 10

  notifications = new Notification


  new views.ToolSelection
    el: ".toolSettings"
  .render()

  new views.ColorSelector
    el: ".colorSelector"
    model: toolSettings
  .render()


  new views.SizeSelector
    el: ".sizeSelector"
    model: toolSettings
  .render()


  new views.ToolSelector
    el: ".toolSelector"
    model: toolSettings
  .render()


  menu = new views.Menu
    el: ".menu"
    model: toolSettings

  menu.render()



  area = new DrawArea
    el: ".whiteboard"

  window._area = area

  menu.bind "publish", ->

    linkView = new views.PublicLink
      el: ".lightbox"
      model: roomModel
      area: area

    linkView.render()

    linkView.bind "published", -> notifications.info "Drawing published"


  statusView = new views.Status
    el: ".status"
    model: status = new models.StatusModel

  status.set status: "starting"


  socket.on "clientJoined", (client) ->
    status.addClient client
    notifications.info "#{ client.browser } joined. We have now #{ status.getClientCount() } other users"


  socket.on "clientParted", (client) ->
    status.removeClient client
    notifications.info "#{ client.browser } parted. We have now #{ status.getClientCount() } other users"

  navigation = new views.Navigation
    socket: socket
    model: roomModel
    el: ".navigation"

  navigation.render()

  if hasTouch
    Input = drawers.TouchInput
  else
    Input = drawers.MouseInput

  bg = new Background
    model: roomModel
    el: "canvas.main"
    socket: socket
    area: area

  bg.bind "bgsaved", -> notifications.info "Background saved"


  main = new maindrawer.Main
    model: roomModel
    toolSettings: toolSettings
    id: helpers.guidGenerator()
    area: area
    socket: socket
    status: status
    input: new Input
      el: "canvas.localBuffer"

  main.bind "ready", ->
    $("canvas.loading").removeClass "loading"
    $("div.loading").remove()
    # http://www.html5rocks.com/en/mobile/mobifying.html#toc-optimizations-scrolling
    window.scrollTo 0, 100



