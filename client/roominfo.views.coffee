
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


class views.RoomInfo extends Backbone.View

  constructor: ({ @socket, @notifications }) ->
    super
    source = $(".roomInfoTemplate").html()
    @template = Handlebars.compile source

    @model.bind "change:persistent", => @render()

  events:
    "tap button.delete": "delete"
    "tap button.persist": "persist"

  delete: ->
    # TODO: Do not use crappy blocking dialogs
    if confirm "Are sure? This cannot be undone"
      @socket.emit "remove", =>
        @notifications.info "This drawing is now removed."
        setTimeout ->
          window.location = "/"
        , 2000

  persist: ->
    @socket.emit "persist", =>
      @model.set persistent: true
      @notifications.info "Room persisted"

  render: ->
    $(@el).html @template
      persistent: @model.get "persistent"
      name: @model.get "roomName"


