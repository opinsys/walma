
views = NS "PWI.views"

class views.Whiteboard extends Backbone.View

  constructor: (opts) ->
    super

    @ctx = @el.getContext('2d')

    console.log "canvas is", @ctx


