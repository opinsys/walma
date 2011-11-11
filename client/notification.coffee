
_  = require 'underscore'
Backbone = require "backbone"

notification = NS "PWB.notification"


class notification.Notification extends Backbone.View

  constructor: ->
    super

  info: (msg) ->
    jQuery.noticeAdd({ text: "INFO: #{ msg }" })

  warning: (msg) ->
    jQuery.noticeAdd({ text: "WARNING: #{ msg }" })

  error: (msg) ->
    jQuery.noticeAdd({ text: "ERROR:: #{ msg }" })

