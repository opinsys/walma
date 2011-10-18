

class exports.Drawing

  constructor: (@name, @collection) ->

  addDraw: (draw, cb) ->
    @collection.update name: @name,
      $push: history: draw
    , (err, coll) -> cb? err


  fetch: (cb) ->

    @collection.find(name: @name).nextObject (err, doc) =>
      return cb? err if err
      if doc
        @_doc = doc
        cb null, doc
      else
        @collection.insert
          name: @name
          created: Date.now()
        ,
          safe: true
        , (err, docs) =>
          return cb? err if err
          @_doc = doc
          cb null, docs[0]


