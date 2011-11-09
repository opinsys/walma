
Backbone = require "backbone"

views = NS "PWB.drawers.views"



class views.Navigation extends Backbone.View

  # events:
  #   "tap a": "navigate"

  constructor: ->
    super
    @$("a").bind "tap", (e) => @navigate(e)

  render: ->
    @$(".next").attr "href", "/#{ @model.get "roomName" }/" + (@model.get("position") + 1)
    @$(".prev").attr "href", "/#{ @model.get "roomName" }/" + (@model.get("position") - 1)

  navigate: (e) ->
    window.location = e.target.href
