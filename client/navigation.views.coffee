
Backbone = require "backbone"

views = NS "PWB.drawers.views"



class views.Navigation extends Backbone.View

  events:
    "tap .next": "navigateToNext"
    "tap .prev": "navigateToPrev"
    "tap .remote": "toggleRemote"
    # XXX
    "tap .publish": "triggerPublish"

  # XXX
  triggerPublish: ->
    @trigger "publish"



  constructor: (opts) ->
    super

    {@socket} = opts
    {@settings} = opts

    @socket.on "changeSlide", (position) =>
      @navigate parseInt position, 10

    @settings.bind "change:remote", => @render()



  toggleRemote: ->
    @settings.set remote: !@settings.get("remote")
    @render()

  update: ->
    @delegateEvents()

  render: ->

    if @model.get("position") <= 1
      @$(".prev").hide()
    else
      @$(".prev").show()

    if @settings.get "remote"
      @$(".remote").parent().addClass "selected"
    else
      @$(".remote").parent().removeClass "selected"



  navigateToNext: (e) ->
    e.preventDefault()
    @navigate @model.get("position") + 1
    false

  navigateToPrev: (e) ->
    e.preventDefault()
    @navigate @model.get("position") - 1
    false


  navigate: (position) ->
    return if position < 1

    url = "/#{ @model.get "roomName" }/" + position


    if not @settings.get "remote"
      window.location = url
    else
      console.log "Emiting change"
      @socket.emit "changeSlide", position, ->
        window.location = url
        console.log "change"

