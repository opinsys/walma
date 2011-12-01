
_  = require 'underscore'
Backbone = require "backbone"

notification = NS "PWB.notification"
views = NS "PWB.drawers.views"

class notification.Notification extends Backbone.View

  constructor: ->
    super

  info: (msg) ->
    console.log "INFO: #{ msg }"
    jQuery.noticeAdd({ text: "INFO: #{ msg }" })

  warning: (msg) ->
    console.log "WARNING: #{ msg }"
    jQuery.noticeAdd({ text: "WARNING: #{ msg }" })

  error: (msg) ->
    console.log "ERROR: #{ msg }"
    e = new views.InfoBox
      el: ".lightbox"
      type: "Error"
      msg: msg

    e.render()
