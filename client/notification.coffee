
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
    jQuery.noticeAdd
      text: "WARNING: #{ msg }"
      stayTime: 5000

  infoModal: (msg, type="Info") ->
    console.log "INFO: #{ msg }"
    e = new views.InfoBox
      type: info
      msg: msg
      stayTime: 5000

    e.render()

  error: (msg) ->
    console.log "ERROR: #{ msg }"
    e = new views.InfoBox
      type: "Error"
      msg: msg

    e.render()
