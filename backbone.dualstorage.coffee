'use strict'

# A simple module to replace `Backbone.sync` with *localStorage*-based
# persistence. Models are given GUIDS, and saved into a JSON object. Simple
# as that.

# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Generate a pseudo-GUID by concatenating random hexadecimal.
guid = ->
  S4() + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4()

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
class window.Store
  sep: '' # previously '-'

  constructor: (name) ->
    @name = name
    store = localStorage.getItem(@name)
    @records = (store and store.split(',')) or []

  # Save the current state of the **Store** to *localStorage*.
  save: ->
    localStorage.setItem @name, @records.join(',')

  # Add a model, giving it a (hopefully)-unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model) ->
    console.log 'creating', model, 'in', @name
    if not _.isObject(model) then return model
    if model.attributes? then model = model.attributes
    if not model.id then model.id = guid()
    localStorage.setItem @name + @sep + model.id, JSON.stringify(model)
    @records.push model.id.toString()
    @save()
    model

  # Update a model by replacing its copy in `this.data`.
  update: (model) ->
    console.log 'updating', model, 'in', @name
    localStorage.setItem @name + @sep + model.id, JSON.stringify(model)
    if not _.include(@records, model.id.toString())
      @records.push model.id.toString()
    @save()
    model

  # Retrieve a model from `this.data` by id.
  find: (model) ->
    console.log 'finding', model, 'in', @name
    JSON.parse localStorage.getItem(@name + @sep + model.id)

  # Return the array of all models currently in storage.
  findAll: ->
    console.log 'findAlling'
    for id in @records
      JSON.parse localStorage.getItem(@name + @sep + id)

  # Delete a model from `this.data`, returning it.
  destroy: (model) ->
    console.log 'trying to destroy', model, 'in', @name
    localStorage.removeItem @name + @sep + model.id
    @records = _.reject(@records, (record_id) ->
      record_id is model.id.toString()
    )
    @save()
    model

# Override `Backbone.sync` to use delegate to the model or collection's
# *localStorage* property, which should be an instance of `Store`.
localsync = (method, model, options, error) ->
  # Backwards compatibility with Backbone <= 0.3.3
  if typeof options is 'function'
    options =
      success: options
      error: error

  store = model.localStorage or model.collection.localStorage

  resp = switch method
    when 'read'
      if model.id then store.find(model) else store.findAll()
    when 'create'
      store.create(model)
    when 'update'
      store.update(model)
    when 'delete'
      store.destroy(model)

  if resp
    options.success resp
  else
    options.error 'Record not found'


# Helper function to get a URL from a Model or Collection as a property
# or as a function.
getUrl = (object) ->
  if not (object and object.url) then return null
  if _.isFunction(object.url) then object.url() else object.url

# Helper function to run parseBeforeLocalSave() in order to
# parse a remote JSON response before caching locally
parseRemoteResponse = (object, response) ->
  if not (object and object.parseBeforeLocalSave) then return response
  if _.isFunction(object.parseBeforeLocalSave) then object.parseBeforeLocalSave(response)

# Throw an error when a URL is needed, and none is supplied.
urlError = ->
  throw new Error 'A "url" property or function must be specified'

# Map from CRUD to HTTP for our default `Backbone.sync` implementation.
methodMap =
  'create': 'POST'
  'update': 'PUT'
  'delete': 'DELETE'
  'read'  : 'GET'

onlineSync = Backbone.sync

dualsync = (method, model, options) ->
  console.log 'dualsync', method, model, options
  store = new Store getUrl(model)

  switch method
    when 'read'
      if store
        response = if model.id then store.find(model) else store.findAll()

        if not _.isEmpty(response)
          console.log 'getting local', response, 'from', store
          options.success response
          return

        success = options.success
        options.success = (resp, status, xhr) ->
          console.log 'got remote', resp, 'putting into', store
          resp = parseRemoteResponse(model, resp)
          if _.isArray resp
            for i in resp
              console.log 'trying to store', i
              store.create i
          else
            store.create resp

          success resp

      if not model.local
        onlineSync(method, model, options)

    when 'create'
      if not model.local and options.remote != false
        onlineSync(method, model, options)
      store.create(model)

    when 'update'
      if not model.local and options.remote != false
        onlineSync(method, model, options)
      store.update(model)

    when 'delete'
      if not model.local and options.remote != false
        onlineSync(method, model, options)
      store.destroy(model)

Backbone.sync = dualsync
