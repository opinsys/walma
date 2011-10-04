
# Main namespace object for Puavo Whiteboard
window["PWI"] = root = {}

# Namespace tool for accessing our namespace
# Usage:
#   bar = NS "foo.bar"
window.NS = (nsString) ->
  parent = root
  for ns in nsString.split "."
    current = parent[ns]
    # Create new namespace if it is missing
    current = parent[ns] = {} if not current?
  current


# Do not die if we have no logging function. Eg. FF without Firebug.
if not window.console?.log?
  window.console =
    log: ->

