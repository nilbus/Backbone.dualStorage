window = require('./spec_helper').window

describe 'monkey patching', ->
  it 'aliases Backbone.sync to onlineSync', ->
    expect(window.onlineSync).toBeDefined()
    expect(window.onlineSync.identity).toEqual('sync')

describe 'offline sync', ->
  describe 'syncDirtyAndDestroyed', ->
    xit 'calls syncDirty and syncDestroyed', ->

  describe 'syncDirty', ->
    xit 'finds and saves all dirty models', ->

  describe 'syncDestroyed', ->
    xit 'finds all models marked as destroyed and destroys them', ->
