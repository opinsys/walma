Backbone = require "backbone"
_  = require 'underscore'

models = NS "PWB.drawers.models"



# Model for client only settings. Such as selected tool etc.
# TODO: Named storage
class models.ToolSettings extends Backbone.Model
  defaults:
    tool: "Pencil"
    size: 5
    color: "black"
    panningSpeed: null

  constructor: ->
    super

    if localStorage.settings
      $.extend @attributes, JSON.parse localStorage.settings

    @bind "change", => @save()

  save: ->
    localStorage.settings = JSON.stringify @attributes





# Persistent shared model between clients.
class models.RoomModel extends Backbone.Model

  defaults:
    background: false
    publishedImage: false
    name: null
    persistent: false

  constructor: (opts) ->
    super
    {@socket} = opts

    # updateAttrs is a socket message that updates models on all clients
    @socket.on "updateAttrs", (attrs) =>

      # If remote changed the background we need to clear this local cache
      if attrs.background
        delete @backgroundDataURL

      @set attrs


  deleteBackground: (cb=->) ->
    @socket.emit "backgroundDelete", cb
    @set background: null


  setPublishedImage: (dataURL, cb=->) ->
    @socket.emit "publishedImageData", dataURL, =>
      @set publishedImage: new Date().getTime()
      cb()

  _setBackgroundURLFromFile: (file, cb=->) ->

    # if file it must be a dataURL (base64 with metadata)
    if typeof file is "string"
      @backgroundDataURL = file
      cb()
      return

    # Local file object from file input
    reader = new FileReader()
    reader.onload = =>
      @backgroundDataURL = reader.result
      cb()
    reader.readAsDataURL file



  saveBackground: (file, cb=->) ->
    async.parallel [
      (cb) =>
        @postImage file, type: "background", cb
    ,
      (cb) =>
        @_setBackgroundURLFromFile file, =>
          @set background: new Date().getTime()
          cb()
    ], (err) =>
      if err
        alert "failed to save background"
      else
        cb()
        @socket.emit "updateAttrs",
          background: @get "background"


  # Returns xhr object
  postImage: (file, extra={}, cb) ->
    form = new FormData()
    form.append "image", file
    for k, v of extra
      form.append k, v

    xhr = new XMLHttpRequest()
    i = 0

    $(xhr).bind "progress", (e) ->
      console.log "progress event", ++i

    $(xhr).bind "load", -> 
      console.log "image sent"
      cb()

    $(xhr).bind "error abort", (e) ->
      console.log "failed to sent image"
      cb e, xhr

    xhr.open "POST", @getImagePostURL()
    xhr.send form

    xhr


  getBackgroundURL: ->
    # We created the background. No need to download it.
    return @backgroundDataURL if @backgroundDataURL

    "#{ location.protocol }//#{ location.host }/#{ @get "roomName" }/bg?v=#{ @get "background" }"

  getPublishedImageURL: ->
    "#{ location.protocol }//#{ location.host }/#{ @get "roomName" }/published.png"

  getImagePostURL: ->
    "#{ location.protocol }//#{ location.host }/#{ @get "roomName" }/image"

  getCacheImageURL: (pos) ->
    "/#{ @get "roomName" }/bitmap/#{ pos }"




# Model for drawing statistics. Mainly for debugging purposes.
class models.StatusModel extends Backbone.Model

  defaults:
    status: "starting"

    cachedDraws: 0
    startDraws: 0
    userDraws: 0
    remoteDraws: 0
    totalDraws: 0
    lag: "n/a "
    position:
      x: 0
      y: 0
    areaSize:
      width: 0
      height: 0
    drawingSize:
      width: 0
      height: 0



  constructor: ->
    super
    @loading = true
    @bind "change", =>
      if @get("status") is "ready"
        @loading = false
      @set totalDraws:(
        @get("cachedDraws") +
        @get("userDraws") +
        @get("remoteDraws") +
        @get("startDraws")
      )


  addClient: (client) ->
    clients = @get("clients") or {}
    clients[client.id] = client
    @set clients: clients

  removeClient: (client) ->
    clients = @get("clients") or {}
    delete clients[client.id]
    @set clients: clients


  getClientCount: ->
    _.size @get("clients") or {}


  addUserDraw: (i=1)->
    @set userDraws: @get("userDraws") + i

  addRemoteDraw: (i=1)->
    if not @loading
      @set remoteDraws: @get("remoteDraws") + i

