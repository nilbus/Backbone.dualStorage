window = require('./spec_helper').window
Backbone = window.Backbone

describe 'standard Backbone.sync methods', ->
  xit 'creates records', ->
  xit 'reads records', ->
  xit 'updates records', ->
  xit 'deletes records', ->

describe 'model and collection options', ->
  xit 'respects the remote only option', ->
  xit 'respects the local only option', ->
  xit 'marks records dirty when options.remote is false, except if the model/collection is marked as local', ->
  xit 'filters responses through parseBeforeLocalSave when defined on the model or collection', ->
