Backbone = require "backbone"
_  = require 'underscore'

background = NS "PWB.background"

class background.Background extends Backbone.View

  constructor: (opts) ->
    super
    {@socket} = opts
    {@area} = opts
    @bindDrag()

    @model.bind "change:background", =>
      # Background has been updated. Lets just append timestamp to the url so
      # it will get reloaded.
      console.log "BG model bind"
      @area.setBackground "#{ @model.getBackgroundURL() }?v=#{ new Date().getTime() }"


  bindDrag: ->

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
      reader = new FileReader
      reader.onload = @fileRead
      reader.readAsDataURL e.originalEvent.dataTransfer.files[0]

  fileRead: (e) =>
    dataURL = e.target.result
    @area.setBackground dataURL
    @model.setBackground dataURL, =>
      @trigger "bgsaved"

