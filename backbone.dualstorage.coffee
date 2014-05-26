###
Backbone dualStorage Adapter v1.1.0

A simple module to replace `Backbone.sync` with *localStorage*-based
persistence. Models are given GUIDS, and saved into a JSON object. Simple
as that.
###

# Use LocalStorageAdapter as default adapter.
Backbone.storageAdapter = new Backbone.storageAdapters.LocalStorageAdapter

# LocalStorage is not actually async, so we can call initialize here and
# continue safely. But when using a real async StorageAdapter, you should
# wait for initialize() to resolve before trying to do any sync operation.
Backbone.storageAdapter.initialize()

# Use default Store class provided by this library.
# Backbone.Store = Store

# Make it easy for collections to sync dirty and destroyed records
# Simply call collection.syncDirtyAndDestroyed()
Backbone.Collection.prototype.syncDirty = ->
  storeName = result(@, 'storeName') || result(@, 'url')
  Backbone.storageAdapter.getItem("#{storeName}_dirty").then (store) =>
    ids = (store and store.split(',')) or []
    models = ((if id.length == 36 then @findWhere(id: id) else @get(id)) for id in ids)
    $.when (model.save() for model in models when model)...

Backbone.Collection.prototype.syncDestroyed = ->
  storeName = result(@, 'storeName') || result(@, 'url')
  Backbone.storageAdapter.getItem("#{storeName}_destroyed").then (store) =>
    ids = (store and store.split(',')) or []
    models = (new @model(id: id) for id in ids)
    (model.collection = @ for model in models)
    $.when (model.destroy() for model in models)...

Backbone.Collection.prototype.syncDirtyAndDestroyed = ->
  @syncDirty().then => @syncDestroyed()

# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
class window.Store
  sep: '' # previously '-'

  constructor: (name) ->
    @name = name
    @dirtyName = "#{name}_dirty"
    @destroyedName = "#{name}_destroyed"
    @records = []

  initialize: ->
    @recordsOn(@name).done (result) =>
      @records = result || []

  # Generates an unique id to use when saving new instances into localstorage
  # by default generates a pseudo-GUID by concatenating random hexadecimal.
  # you can overwrite this function to use another strategy
  generateId: ->
    S4() + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4()

  getStorageKey: (model) ->
    if _.isObject model then model = model.id
    @name + @sep + model

  # Save the current state of the **Store** to *localStorage*.
  save: ->
    Backbone.storageAdapter.setItem @name, @records.join(',')

  recordsOn: (key) ->
    Backbone.storageAdapter.getItem(key).then (store) ->
      (store and store.split(',')) or []

  dirty: (model) ->
    @recordsOn(@dirtyName).then (dirtyRecords) =>
      if not _.include(dirtyRecords, model.id.toString())
        dirtyRecords.push model.id.toString()
        return Backbone.storageAdapter.setItem(@dirtyName, dirtyRecords.join(',')).then -> model
      model

  clean: (model, from) ->
    store = "#{@name}_#{from}"
    @recordsOn(store).then (dirtyRecords) =>
      if _.include dirtyRecords, model.id.toString()
        return Backbone.storageAdapter.setItem(store, _.without(dirtyRecords, model.id.toString()).join(',')).then -> model
      model

  destroyed: (model) ->
    @recordsOn(@destroyedName).then (destroyedRecords) =>
      if not _.include destroyedRecords, model.id.toString()
        destroyedRecords.push model.id.toString()
        Backbone.storageAdapter.setItem(@destroyedName, destroyedRecords.join(',')).then -> model
      model

  # Add a model, giving it a unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model) ->
    if not _.isObject(model) then return $.Deferred().resolve model
    if not model.id
      model.id = @generateId()
      model.set model.idAttribute, model.id
    Backbone.storageAdapter.setItem(@getStorageKey(model), JSON.stringify(model)).then =>
      @records.push model.id.toString()
      @save().then => model

  # Update a model by replacing its copy in `this.data`.
  update: (model) ->
    Backbone.storageAdapter.setItem(@getStorageKey(model), JSON.stringify(model)).then =>
      if not _.include(@records, model.id.toString())
        @records.push model.id.toString()
      @save().then => model

  clear: ->
    $.when((Backbone.storageAdapter.removeItem(@getStorageKey id) for id in @records)...).then =>
      @records = []
      @save()

  hasDirtyOrDestroyed: ->
    Backbone.storageAdapter.getItem(@dirtyName).then (dirty) =>
      Backbone.storageAdapter.getItem(@destroyedName).then (destroyed) =>
        not _.isEmpty(dirty) or not _.isEmpty(destroyed)

  # Retrieve a model from `this.data` by id.
  find: (model) ->
    Backbone.storageAdapter.getItem(@getStorageKey(model)).then (modelAsJson) ->
      return null if modelAsJson == null
      JSON.parse modelAsJson

  # Return the array of all models currently in storage.
  findAll: ->
    $.when((Backbone.storageAdapter.getItem(@getStorageKey id) for id in @records)...).then (models...) ->
      (JSON.parse(model) for model in models)

  # Delete a model from `this.data`, returning it.
  destroy: (model) ->
    Backbone.storageAdapter.removeItem(@getStorageKey(model)).then =>
      @records = _.without @records, model.id.toString()
      @save().then -> model

callbackTranslator =
  needsTranslation: Backbone.VERSION == '0.9.10'

  forBackboneCaller: (callback) ->
    if @needsTranslation
      (model, resp, options) -> callback.call null, resp
    else
      callback

  forDualstorageCaller: (callback, model, options) ->
    if @needsTranslation
      (resp) -> callback.call null, model, resp, options
    else
      callback

# Override `Backbone.sync` to use delegate to the model or collection's
# *localStorage* property, which should be an instance of `Store`.
localSync = (method, model, options) ->
  isValidModel = (method is 'clear') or (method is 'hasDirtyOrDestroyed')
  isValidModel ||= model instanceof Backbone.Model
  isValidModel ||= model instanceof Backbone.Collection

  if not isValidModel
    throw new Error 'model parameter is required to be a backbone model or collection.'

  store = new Store options.storeName
  store.initialize().then =>

    promise = switch method
      when 'read'
        if model.id
          store.find(model)
        else
          store.findAll()
      when 'hasDirtyOrDestroyed'
        store.hasDirtyOrDestroyed()
      when 'clear'
        store.clear()
      when 'create'
        store.find(model).then (preExisting) ->
          unless options.add and not options.merge and preExisting
            store.create(model).then (model) ->
              if options.dirty
                return store.dirty(model).then ->
                  model
              model
          else
            preExisting
      when 'update'
        store.update(model).then (model) ->
          if options.dirty
            store.dirty(model)
          else
            store.clean(model, 'dirty')
      when 'delete'
        store.destroy(model).then ->
          if options.dirty
            store.destroyed(model)
          else
            if model.id.toString().length == 36
              store.clean(model, 'dirty')
            else
              store.clean(model, 'destroyed')

    promise.then (response) ->
      response = response.attributes if response?.attributes

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

# Helper function to run parseBeforeLocalSave() in order to
# parse a remote JSON response before caching locally
parseRemoteResponse = (object, response) ->
  if not (object and object.parseBeforeLocalSave) then return response
  if _.isFunction(object.parseBeforeLocalSave) then object.parseBeforeLocalSave(response)

modelUpdatedWithResponse = (model, response) ->
  modelClone = new Backbone.Model
  modelClone.idAttribute = model.idAttribute
  modelClone.set model.attributes
  modelClone.set modelClone.parse response
  modelClone

backboneSync = Backbone.sync
onlineSync = (method, model, options) ->
  options.success = callbackTranslator.forBackboneCaller(options.success)
  options.error   = callbackTranslator.forBackboneCaller(options.error)
  backboneSync(method, model, options)

dualSync = (method, model, options) ->
  options.storeName = result(model.collection, 'storeName') || result(model, 'storeName') ||
                      result(model.collection, 'url')       || result(model, 'urlRoot')   || result(model, 'url')
  options.success = callbackTranslator.forDualstorageCaller(options.success, model, options)
  options.error   = callbackTranslator.forDualstorageCaller(options.error, model, options)

  # execute only online sync
  return onlineSync(method, model, options) if result(model, 'remote') or result(model.collection, 'remote')

  # execute only local sync
  local = result(model, 'local') or result(model.collection, 'local')
  options.dirty = options.remote is false and not local
  return localSync(method, model, options) if options.remote is false or local

  # execute dual sync
  options.ignoreCallbacks = true

  success = options.success
  error = options.error

  switch method
    when 'read'
      localSync('hasDirtyOrDestroyed', model, options).then (hasDirtyOrDestroyed) ->
        if hasDirtyOrDestroyed
          localSync(method, model, options).then (response) ->
            success response
        else
          options.success = (resp, status, xhr) ->
            resp = parseRemoteResponse(model, resp)

            go = ->
              if _.isArray resp
                collection = model
                idAttribute = collection.model.prototype.idAttribute
                models = []
                for modelAttributes in resp
                  model = collection.get(modelAttributes[idAttribute])
                  if model
                    responseModel = modelUpdatedWithResponse(model, modelAttributes)
                  else
                    responseModel = new collection.model(modelAttributes)
                  models.push responseModel
                $.when((localSync('create', m, options) for m in models)...).then ->
                  success(resp, status, xhr)
              else
                responseModel = modelUpdatedWithResponse(model, resp)
                localSync('create', responseModel, options).then ->
                  success(resp, status, xhr)

            if not options.add
              localSync('clear', model, options).then go
            else
              go()

          options.error = (resp) ->
            localSync(method, model, options).then (result) ->
              success result

          onlineSync(method, model, options)

    when 'create'
      options.success = (resp, status, xhr) ->
        updatedModel = modelUpdatedWithResponse model, resp
        localSync(method, updatedModel, options).then ->
          success(resp, status, xhr)
      options.error = (resp) ->
        options.dirty = true
        localSync(method, model, options).then (result) ->
          success result

      onlineSync(method, model, options)

    when 'update'
      if _.isString(model.id) and model.id.length == 36
        temporaryId = model.id

        options.success = (resp, status, xhr) ->
          updatedModel = modelUpdatedWithResponse model, resp
          model.set model.idAttribute, temporaryId, silent: true
          localSync('delete', model, options).then ->
            localSync('create', updatedModel, options).then ->
              success(resp, status, xhr)
        options.error = (resp) ->
          options.dirty = true
          model.set model.idAttribute, temporaryId, silent: true
          localSync(method, model, options).then (result) ->
            success result

        model.set model.idAttribute, null, silent: true
        onlineSync('create', model, options)
      else
        options.success = (resp, status, xhr) ->
          updatedModel = modelUpdatedWithResponse model, resp
          localSync(method, updatedModel, options).then ->
            success(resp, status, xhr)
        options.error = (resp) ->
          options.dirty = true
          localSync(method, model, options).then (result) ->
            success

        onlineSync(method, model, options)

    when 'delete'
      if _.isString(model.id) and model.id.length == 36
        localSync(method, model, options)
      else
        options.success = (resp, status, xhr) ->
          localSync(method, model, options).then ->
            success(resp, status, xhr)
        options.error = (resp) ->
          options.dirty = true
          localSync(method, model, options).then (result) ->
            success result

        onlineSync(method, model, options)

Backbone.sync = dualSync
