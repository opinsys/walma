$ = jQuery
# Namespace for this app is PWI
#

# Namespace tool for accessing our namespace
#
# Usage:
#   bar = NS "PWB.foo.bar"
#
window.NS = (nsString) ->
  parent = window
  for ns in nsString.split "."
    # Create new namespace if it is missing
    parent = parent[ns] ?= {}
  parent # return the asked namespace




$ ->
  if Stats?
    window.stats = new Stats
    $("body").append stats.domElement
  else
    window.stats =
      update: ->



# Smoother navigation for touch devices
# Just use tap event instead of click
$.support.touch = 'ontouchstart' of window
$ ->
  if $.support.touch
    $('body').bind 'touchstart', (e) ->
      $(e.target).addClass "touching"
    $('body').bind 'touchend', (e) ->
      $(e.target).removeClass "touching"
      $(e.target).trigger('tap')
  else
    $('body').bind 'mouseup', (e) ->
      $(e.target).trigger('tap')



# Do not die if we have no logging function. Eg. FF without Firebug.
if not window.console?.log?
  window.console =
    log: ->


helpers = NS "PWB.helpers"

helpers.notImplemented = (msg) -> ->
  throw new Error "Not implemented: #{ msg } for #{ @constructor.name }"

helpers.guidGenerator = ->
  S4 = ->
    (((1 + Math.random()) * 65536) | 0).toString(16).substring(1)
  (S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4())
