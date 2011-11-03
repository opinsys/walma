
{Db, Connection, Server} = require "mongodb"
{Drawing} = require "../lib/drawmodel"

prepare = require "./specdb"

generateName = require "../lib/namegenerator"


beforeEach ->
  asyncSpecWait()
  prepare.call this, (db) ->
    db.collection "testdrawings", (err, coll) =>
      throw err if err
      Drawing.collection = coll
      Drawing.db = db
      db.collection "whiteboard-config", (err, coll) ->
        throw err if err
        coll.insert
          _id: "config"
        ,
          safe: true
        , (err) ->
          throw err if err
          asyncSpecDone()

afterEach ->
  this.db.close ->

describe "drawing name creator", ->

  it "creates new name", ->

    asyncSpecWait()
    db = this.db
    generateName (err, name) ->
      expect(err).toBeFalsy "We should have config object"
      expect(name).toEqual "screenshot-1"
      asyncSpecDone()


  it "won't clash with drawing names", ->
    asyncSpecWait()
    db = this.db
    d = new Drawing "screenshot-1"
    d.fetch ->
      generateName (err, name) ->
        expect(err).toBeFalsy "We should have config object"
        expect(name).toEqual "screenshot-2"
        asyncSpecDone()
