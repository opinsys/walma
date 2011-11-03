
{Db, Connection, Server} = require "mongodb"

module.exports = prepare = (cb) ->
  this.db = db = new Db 'whiteboard-test',
    new Server "localhost", Connection.DEFAULT_PORT,
      auto_reconnect: true

  db.open (err) ->
    throw err if err
    db.dropDatabase (err, done) ->
      cb db

