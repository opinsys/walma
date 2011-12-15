
fs = require "fs"

async = require "async"
{Db, Connection, Server} = require "mongodb"
{Drawing} = require "./lib/drawmodel"


exports.open = open = (config, cb=->) ->
  db = new Db config.mongoDBName,
    new Server config.mongoHost, config.mongoPort,

  db.open (err) ->
    if err
      console.log "Could not open the database", err.trace
      process.exit 1

    db.collection "drawings", (err, collection) ->
      throw err if err
      Drawing.collection = collection
      Drawing.db = db
      console.log "Ensuring indexes"
      async.series [
        (cb) -> collection.ensureIndex "name", cb
      ,
        (cb) -> collection.ensureIndex "persistent", cb
      ], (err) ->
        throw err if err
        console.log "Indexes created"
        cb null, db


  db

exports.populate = (config, cb=->) ->
  open config, (err, db) ->
    throw err if err
    db.collection "whiteboard-config", (err, coll) ->
      throw err if err
      coll.insert
        _id: "config"
      , safe: true
      , (err) ->
        throw err if err
        console.log "Config doc created"
        cb()



# Populate db if this file is directly executed
if require.main is module
  config = JSON.parse fs.readFileSync __dirname + "/config.json"
  exports.populate config, ->
    console.log "Database bootstrapped"
    process.exit 0

