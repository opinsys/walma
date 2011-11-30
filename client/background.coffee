Backbone = require "backbone"
_  = require 'underscore'

background = NS "PWB.background"
views = NS "PWB.drawers.views"




class views.BackgroundSelect extends Backbone.View

  events:
    "tap .backgroundDelete": "deleteBackground"
    "change input": "setBackgroundFromEvent"

  constructor: ({ @area, @background }) ->
    super

    source = $("script.backgroundSelectTemplate").html()
    @template = Handlebars.compile source

    @bindDragAndDrop()


  deleteBackground: ->
    @model.deleteBackground()
    @trigger "select"


  setBackgroundFromEvent: (e) ->
    @readFileToModel e.target.files[0]


  readFileToModel: (file) ->
    reader = new FileReader()
    reader.onload = =>
      @trigger "select"
      @model.saveBackground reader.result, =>
        @render()
    reader.readAsDataURL file


  render: ->
    $(@el).html @template

    if not @area.hasBackground()
      @$("button.backgroundDelete").remove()


  bindDragAndDrop: ->

    $(document).bind "dragenter", (e) ->
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'

    $(document).bind "dragover", (e) ->
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'

    $(document).bind "dragleave", (e) -> e.preventDefault()
    $(document).bind "dragend", (e) -> e.preventDefault()
    $(document).bind "drop", (e) =>
      e.preventDefault()
      @readFileToModel e.originalEvent.dataTransfer.files[0]

