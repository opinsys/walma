
PWB = NS "PWB"
{DrawArea, Background} = PWB

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
  $(window).bind "touchstart", false
  $(window).bind "touchmove", false

  [__, roomName, position] = window.location.pathname.split("/")
  settings = new models.SettingsModel

  settings.set
    roomName: roomName
    position: parseInt position, 10

  notifications = new Notification


  new views.ToolSelection
    el: ".toolSettings"
  .render()

  new views.ColorSelector
    el: ".colorSelector"
    model: settings
  .render()


  new views.SizeSelector
    el: ".sizeSelector"
    model: settings
  .render()


  new views.ToolSelector
    el: ".toolSelector"
    model: settings
  .render()


  menu = new views.Menu
    el: ".menu"
    model: settings

  menu.render()



  area = new DrawArea
    main: $("canvas.main").get 0
    localBuffer: $("canvas.localBuffer").get 0
    remoteBuffer: $("canvas.remoteBuffer").get 0
    soft: ".bg-size"


  menu.bind "publish", ->
    area.getDataURLWithBackground (err, dataURL) ->

      linkView = new views.PublicLink
        el: ".lightbox"
        imgUrl: settings.getPublishedImageURL()
        imgDataURL: dataURL

      linkView.render()

      socket.emit "publishImg", dataURL, ->
        notifications.info "Image published"
        linkView.setSaved()



  statusView = new views.Status
    el: ".status"
    model: status = new models.StatusModel

  status.set status: "starting"

  socket = io.connect().of("/drawer")

  socket.on "clientJoined", (client) ->
    status.addClient client
    notifications.info "#{ client.browser } joined. We have now #{ status.getClientCount() } other users"


  socket.on "clientParted", (client) ->
    status.removeClient client
    notifications.info "#{ client.browser } parted. We have now #{ status.getClientCount() } other users"

  navigation = new views.Navigation
    socket: socket
    model: settings
    el: ".navigation"

  navigation.render()

  if hasTouch
    Input = drawers.TouchInput
  else
    Input = drawers.MouseInput

  bg = new Background
    model: settings
    el: "canvas.main"
    socket: socket
    area: area

  bg.bind "bgsaved", ->
    notifications.info "Background saved"


  main = new maindrawer.Main
    model: settings
    id: helpers.guidGenerator()
    area: area
    socket: socket
    status: status
    input: new Input
      el: "canvas.localBuffer"

  area.update window.innerWidth, window.innerHeight, true
  $(window).resize ->
    area.update window.innerWidth, window.innerHeight, true

  main.bind "ready", ->
    $("canvas.loading").removeClass "loading"
    $("div.loading").remove()
    # http://www.html5rocks.com/en/mobile/mobifying.html#toc-optimizations-scrolling
    window.scrollTo 0, 100





