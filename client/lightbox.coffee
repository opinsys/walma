
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


class views.LightBox extends Backbone.View

  constructor: ->
    super
    # Close lightbox when tabbed or clicked somewhere else
    #
    # Add small timeout so that event loop gets cleared. Otherwise menu click
    # trigger this.
    setTimeout =>
      $("body").bind "tap", cb = (e) =>
        if $(@el).has(e.target).length is 0
          $("body").unbind "tap", cb
          @remove()
    , 10

  remove: ->
    @$(".content").empty()
    @$(@el).hide()


  render: ->
    @$(@el).show()

class views.PublicLink extends views.LightBox

  constructor: (opts) ->
    super
    {@area} = opts

    source = $(".image-template").html()
    @template = Handlebars.compile source

    @model.bind "change:publishedImage", => @render()



  publishImage: ->
    throw new Error "no data url. Render first" unless @currentImageDataURL

    @model.setPublishedImage @currentImageDataURL, =>
      console.log "Image published"
      @trigger "published"



  render: ->
    super

    if not @currentImageDataURL
      @area.getDataURLWithBackground (err, dataURL) =>
        @currentImageDataURL = dataURL
        @render()
      return


    @$(".content").html @template
      published: @model.get "publishedImage"
      publishedImageURL: @model.getPublishedImageURL()
      currentImageDataURL: @currentImageDataURL

    if @model.get "publishedImage"
      @$("img").bind "tap", (e) =>
        window.open @model.getPublishedImageURL()


    @$("button.publish").bind "tap", => @publishImage()
    @$(".close a").bind "tap", => @remove()
    @$("input").select()


