
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"



class views.Status extends Backbone.View

  constructor: ->
    super
    source = $(".status-template").html()
    @template = Handlebars.compile source
    @model.bind "change", => @render()

  render: ->
    $(@el).html @template @model.toJSON()



class views.RoomInfo extends Backbone.View

  constructor: ->
    super
    source = $(".roomInfoTemplate").html()
    @template = Handlebars.compile source

  events:
    "tap button.delete": "delete"
    "tap button.persist": "persist"

  delete: -> alert "implement me"

  persist: -> alert "implement me"

  render: ->
    $(@el).html @template
      persistent: @model.get "persistent"
      name: @model.get "roomName"


