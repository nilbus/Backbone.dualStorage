helper = require('./spec_helper')
window = helper.window

describe 'the spec_helper context', ->
  it 'is defined', ->
    expect(window).toBeDefined()

  it 'defines Backbone.Collection.prototype.syncDirty', ->
    expect(window.Backbone.Collection.prototype.syncDirty).toBeDefined()
