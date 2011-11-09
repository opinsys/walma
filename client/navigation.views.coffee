
Backbone = require "backbone"

views = NS "PWB.drawers.views"



class views.Navigation extends Backbone.View

  events:
    "tap .remote": "toggleRemote"
    "tap .next": "navigateToNext"
    "tap .prev": "navigateToPrev"

  remote: false

  constructor: (opts) ->
    super

    {@socket} = opts

    @socket.on "changeSlide", (position) =>
      @navigate parseInt position, 10


  render: ->
    # @$(".next").attr "href", "/#{ @model.get "roomName" }/" + (@model.get("position") + 1)
    # @$(".prev").attr "href", "/#{ @model.get "roomName" }/" + (@model.get("position") - 1)

    if @remote
      @$(".remote").html "Remote is on"
    else
      @$(".remote").html "Remote is off"


  toggleRemote: ->
    @remote = !@remote
    @render()

  navigateToNext: (e) ->
    e.preventDefault()
    @navigate @model.get("position") + 1
    false

  navigateToPrev: (e) ->
    e.preventDefault()
    @navigate @model.get("position") - 1
    false


  navigate: (position) ->
    url = "/#{ @model.get "roomName" }/" + position

    if not @remote
      window.location = url
    else
      console.log "Emiting change"
      @socket.emit "changeSlide", position, ->
        window.location = url
        console.log "change"

