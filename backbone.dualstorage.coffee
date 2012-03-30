'use strict'

# A simple module to replace `Backbone.sync` with *localStorage*-based
# persistence. Models are given GUIDS, and saved into a JSON object. Simple
# as that.

# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
class window.Store
  sep: '' # previously '-'

  constructor: (name) ->
    @name = name
    store = localStorage.getItem(@name)
    @records = (store and store.split(',')) or []

  # Generates an unique id to use when saving new instances into localstorage
  # by default generates a pseudo-GUID by concatenating random hexadecimal.
  # you can overwrite this function to use another strategy
  generateId: ->
    S4() + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4()
  
  # Save the current state of the **Store** to *localStorage*.
  save: ->
    localStorage.setItem @name, @records.join(',')

  # Add a model, giving it a (hopefully)-unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model) ->
    console.log 'creating', model, 'in', @name
    if not _.isObject(model) then return model
    if model.attributes? then model = model.attributes
    if not model.id then model.id = @generateId()
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
localsync = (method, model, options) ->
  store = new Store options.storeName

  response = switch method
    when 'read'
      if model.id then store.find(model) else store.findAll()
    when 'create'
      store.create(model)
    when 'update'
      store.update(model)
    when 'delete'
      store.destroy(model)

  unless options.ignoreCallbacks
    if response
      options.success response
    else
      options.error 'Record not found'
  
  response

# If the value of the named property is a function then invoke it;
# otherwise, return it.
# based on _.result from underscore github
result = (object, property) ->
  return null unless object
  value = object[property]
  if _.isFunction(value) then value.call(object) else value

onlineSync = Backbone.sync

dualsync = (method, model, options) ->
  console.log 'dualsync', method, model, options
  
  options.storeName = result(model.collection, 'url') || result(model, 'url')
  
  return onlineSync(method, model, options) if result(model, 'remote') or result(model.collection, 'remote')
  return localsync(method, model, options) if (options.remote == false) or result(model, 'local') or result(model.collection, 'local')
  
  options.ignoreCallbacks = true
  
  switch method
    when 'read'
      response = localsync(method, model, options)

      if not _.isEmpty(response)
        console.log 'getting local', response, 'from', options.storeName
        options.success response
      else
        success = options.success
        options.success = (resp, status, xhr) ->
          console.log 'got remote', resp, 'putting into', options.storeName
          if _.isArray resp
            for i in resp
              console.log 'trying to store', i
              localsync('create', i, options)
          else
            localsync('create', model, options)

          success resp

        onlineSync(method, model, options)

    when 'create'
      onlineSync(method, model, options)
      localsync(method, model, options)

    when 'update'
      onlineSync(method, model, options)
      localsync(method, model, options)

    when 'delete'
      onlineSync(method, model, options)
      localsync(method, model, options)

Backbone.sync = dualsync