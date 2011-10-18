

class exports.Drawing

  Drawing.collection = null

  constructor: (@name) ->
    throw "Collection must be set" unless Drawing.collection

  addDraw: (draw, cb) ->
    Drawing.collection.update name: @name,
      $push: history: draw
    , (err, coll) -> cb? err


  fetch: (cb) ->

    Drawing.collection.find(name: @name).nextObject (err, doc) =>
      return cb? err if err
      if doc
        @_doc = doc
        cb null, doc
      else
        Drawing.collection.insert
          name: @name
          history: []
          created: Date.now()
        ,
          safe: true
        , (err, docs) =>
          return cb? err if err
          @_doc = doc
          cb null, docs[0]


