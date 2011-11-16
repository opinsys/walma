
drawarea = NS "PWB.drawarea"

Backbone = require "backbone"
_  = require 'underscore'

resizeCanvas = (width, height, canvas, cb=->) ->
  img = new Image
  data = canvas.toDataURL("image/png")
  canvas.width = width
  canvas.height = height
  img.onload = =>
    canvas.getContext("2d").drawImage img, 0, 0
    cb()
  img.src = data



class drawarea.DrawArea extends Backbone.View

  constructor: (opts) ->

    # Where the actual drawing is. Including background
    @drawingSize =
      width: 0
      height: 0

    # Area where user can draw. The actual canvas size.
    @areaSize =
      width: 0
      height: 0

    # What user actually sees
    @viewSize =
      width: 0
      height: 0

    # Determines if canvas should be extended
    @dirty = true


    # Scroll position
    @position =
      x: 0
      y: 0

    @bgURL = null

    # Canvases
    @mainCanvas = @$("canvas.main")
    @main = @mainCanvas.get 0
    @localBuffer = @$("canvas.localBuffer").get 0
    @remoteBuffer = @$("canvas.remoteBuffer").get 0


    # Simple div for containing background  that is fast to resize
    @background = @$("div.canvasBackground")

    @syncViewSize()
    $(window).resize => @syncViewSize()


  # Synchronizes view size to the browser window. Should always be smaller than
  # the broswer so that there is nothing to scroll. Tablets has hard time with
  # it.
  syncViewSize: ->
    $(@el).css
      width: (@viewSize.width = $(window).width()) + "px"
      height: (@viewSize.height = $(window).height()) + "px"
      @_updateSize @areaSize, @viewSize.width, @viewSize.height


  getDataURL: ->
    tmp = document.createElement "canvas"
    tmp.width = @drawingSize.width
    tmp.height = @drawingSize.height
    tmp.getContext("2d").drawImage @main, 0, 0
    tmp.toDataURL("image/png")


  # Merges the background and the drawing to a single image. Returns it as
  # dataURL in given callback
  getDataURLWithBackground: (cb) ->
    if not @bgURL
      cb null, @getDataURL()
      return

    img = new Image
    canvas = document.createElement "canvas"
    canvas.width = @drawingSize.width
    canvas.height = @drawingSize.height
    img.onload = =>
      ctx = canvas.getContext "2d"
      ctx.drawImage img, 0, 0
      ctx.drawImage @main, 0, 0
      cb null, canvas.toDataURL("image/png")

    img.src = @bgURL


  # Draw given image or canvas on top of current drawing
  drawImage: (img) ->
    @updateDrawingSizeFromImage img, =>
      @resize =>
        @main.getContext("2d").drawImage img, 0, 0

  setBackground: (url, cb=->) ->
    $(@background).css "background-image", "url(#{ url })"
    @bgURL = url
    @updateDrawingSizeFromImage url, => @resize cb

  updateDrawingSizeFromImage: (url, cb=->) ->
    url = url.src if url.src
    img = new Image
    img.onload =>
      @updateDrawingSize img.width, img.height
      cb null,
        width: img.width
        height: img.height

    img.src = url


  update: ->
    throw new Error "use update size"

  updateDrawingSize: (newWidth, newHeight) ->
    @dirty = @_updateSize @drawingSize, newWidth, newHeight
    @updateAreaSize.apply this, arguments

  updateAreaSize: (newWidth, newHeight) ->
    @dirty = @_updateSize @areaSize, newWidth, newHeight

    if @dirty
      console.log "Drawing area size is dirty!", JSON.stringify @areaSize

  _updateSize: (size, newWidth, newHeight) ->

    dirty = false

    if newWidth > size.width
      size.width = newWidth
      dirty = true

    if newHeight > size.height
      size.height = newHeight
      dirty = true

    dirty


  updateDrawingSizeFromPoint: (point) ->
    @updateDrawingSize point.x, point.y

  softResize: ->
    throw new Error "no soft anymore"


  moveCanvas: (position) ->
    @$("canvas").css
      top: position.x + "px"
      left: position.y + "px"

    @position = position

    if @position.x < 0
      updateDrawingSize position.x*-1 + @areaSize.width, 0
    if @position.y < 0
      updateDrawingSize 0,  position.y*-1 + @areaSize.height

    @dirty



  resize: (cb=->) ->
    return cb() unless @dirty

    resizeCanvas @areaSize.width, @areaSize.height, @main, =>

      for c in [@localBuffer, @remoteBuffer]
        c.width = @areaSize.width
        c.height = @areaSize.height

      @dirty = false
      console.log "Canvas resized", JSON.stringify @areaSize
      @trigger "resize", @areaSize.width, @areaSize.height
      cb()


