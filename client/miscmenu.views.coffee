
Backbone = require "backbone"

views = NS "PWB.drawers.views"


class views.MiscMenu extends Backbone.View

  constructor: ({ @area, @model, @notifications }) ->
    super

  events:
    "tap .publish": "openPublishView"
    "tap .background": "openBackgroundView"

  render: ->
    $(@el).show()

  openBackgroundView: ->
    backgroundSelect = new views.BackgroundSelect
      model: @model
      area: @area
      notifications: @notifications
    @openInLightBox backgroundSelect

  openInLightBox: (view) ->
    view.render()
    box = new views.LightBox
      subviews: [ view ]
    box.render()

  openPublishView: ->
    @trigger "select"

    linkView = new views.PublicLink
      model: @model
      area: @area

    linkView.bind "published", ->
      @trigger "publish"

    @openInLightBox linkView





