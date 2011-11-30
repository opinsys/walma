
_  = require 'underscore'
Backbone = require "backbone"

notification = NS "PWB.notification"

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
    # XXX
    alert "ERROR: #{ msg }"
