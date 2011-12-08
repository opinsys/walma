


# Usage of hash url in Whiteboard. We do not use hash for routing, since in
# this app we can use History api  We will use it as set of flags that can
# enable or disable some features. Like debugging view.


_  = require 'underscore'


class HashTagRouter

  constructor: ->
    @tags = {}
    $(window).bind "hashchange", => @updateTags()

  updateTags: ->
    newTags = {}

    for tag in window.location.hash.substring(1).split ","
      newTags[tag] = true

    if not _.isEqual newTags, @tags
      @tags = newTags

      $(window).trigger "hashtagchange", [this]


  has: (tag) ->
    !! @tags[tag]

  add: (tag) ->

    @tags[tag] = true

    window.location.hash = _.keys(@tags).join ","

PWB = NS "PWB"

tags = new HashTagRouter
PWB.tags = tags
tags.updateTags()

