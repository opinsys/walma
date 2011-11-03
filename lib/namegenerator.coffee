
{Drawing} = require "../lib/drawmodel"

generateName = (cb=->) ->
  Drawing.db.collection "whiteboard-config", (err, collection) ->
    throw err if err
    collection.findAndModify
      _id: "config",
      [['_id','asc']],
      $inc:
        screenshotCount: 1
    ,
      new: true
    , (err, doc) ->
      return cb new Error "config doc is missing" unless doc
      newName = "screenshot-#{ doc.screenshotCount }"
      # Make sure that the new name does not clash with existing
      Drawing.collection.find(name: newName).nextObject (err, doc) ->
        if doc
          generateName cb
        else
          cb err, newName


module.exports = generateName
