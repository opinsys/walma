
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


class views.LightBox extends Backbone.View

  el: ".lightbox"

  constructor: ({ @subviews }) ->
    super
    @subviews = [] unless @subviews

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
    @$(@el).hide()


  render: ->
    @$(".content").children().detach()
    @$(".content").empty()
    @$(".close a").bind "tap", => @remove()
    for view in @subviews
      view.render()
      @$(".content").append view.el
    @$(@el).show()


class views.InfoBox extends views.LightBox

  constructor: ({ @msg, @type }) ->
    super


  render: ->
    super
    @$(".content").html """
      <h1>#{ @type }</h1>
      <p>#{ @msg }</p>
    """



class views.PublicLink extends Backbone.View

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

    if not @currentImageDataURL
      @area.getDataURLWithBackground (err, dataURL) =>
        @currentImageDataURL = dataURL
        @render()
      return


    $(@el).html @template
      published: @model.get "publishedImage"
      publishedImageURL: @model.getPublishedImageURL()
      currentImageDataURL: @currentImageDataURL

    if @model.get "publishedImage"
      @$("img").bind "tap", (e) =>
        window.open @model.getPublishedImageURL()


    @$("button.publish").bind "tap", => @publishImage()
    @$("input").select()


