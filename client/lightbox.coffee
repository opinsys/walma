
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


class views.LightBox extends Backbone.View



  remove: ->
    @$(".content").empty()
    @$(@el).hide()


  render: ->
    @$(@el).show()

class views.PublicLink extends views.LightBox


  constructor: (opts) ->
    super
    {@imgUrl} = opts
    {@imgDataURL} = opts

    source = $(".image-template").html()
    @template = Handlebars.compile source




  render: ->
    super
    @$(".content").html @template @
    @$(".imgLink").click(false).bind "tap", (e) =>
      window.open @imgUrl

    @$(".close a").bind "tap", =>
      @remove()

    @$("input").select()

    # Add small timeout so that event loop gets cleared. Otherwise menu click
    # trigger this.
    setTimeout =>
      $("body").bind "tap", cb = (e) =>
        if $(@el).has(e.target).length is 0
          $("body").unbind "tap", cb
          @remove()
    , 10




  setSaved: ->
    @$(".saving").remove()

