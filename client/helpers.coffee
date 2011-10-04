# Namespace for this app is PWI
#

# Namespace tool for accessing our namespace
#
# Usage:
#   bar = NS "PWI.foo.bar"
#
window.NS = (nsString) ->
  parent = window
  for ns in nsString.split "."
    current = parent[ns]
    # Create new namespace if it is missing
    current = parent[ns] = {} if not current?
  current


# Do not die if we have no logging function. Eg. FF without Firebug.
if not window.console?.log?
  window.console =
    log: ->

