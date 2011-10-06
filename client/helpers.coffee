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


# Do not die if we have no logging function. Eg. FF without Firebug.
if not window.console?.log?
  window.console =
    log: ->


helpers = NS "PWB.helpers"

helpers.notImplemented = (msg) -> ->
  throw new Error "Not implemented: #{ msg } for #{ @constructor.name }"
