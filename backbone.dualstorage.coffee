###
Backbone dualStorage Adapter v1.1.0

A simple module to replace `Backbone.sync` with *localStorage*-based
persistence. Models are given GUIDS, and saved into a JSON object. Simple
as that.
###

# Make it easy for collections to sync dirty and destroyed records
# Simply call collection.syncDirtyAndDestroyed()
Backbone.Collection.prototype.syncDirty = (callback) ->
  url = result(@, 'url')
  storeName = result(@, 'storeName')
  store = localStorage.getItem "#{url}_dirty" || localStorage.getItem "#{storeName}_dirty"
  ids = (store and store.split(',')) or []

  for id in ids
    model = if id.length == 36 then @findWhere(id: id) else @get(id)
    model?.save()

Backbone.Collection.prototype.syncDestroyed = ->
  url = result(@, 'url')
  storeName = result(@, 'storeName')
  store = localStorage.getItem "#{url}_destroyed" || store = localStorage.getItem "#{storeName}_destroyed"
  ids = (store and store.split(',')) or []

  for id in ids
    model = new @model(id: id)
    model.collection = @
    model.destroy()

Backbone.Collection.prototype.syncDirtyAndDestroyed = ->
  @syncDirty()
  @syncDestroyed()

# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
class window.Store
  sep: '' # previously '-'

  constructor: (name) ->
    @name = name
    @records = @recordsOn @name

  # Generates an unique id to use when saving new instances into localstorage
  # by default generates a pseudo-GUID by concatenating random hexadecimal.
  # you can overwrite this function to use another strategy
  generateId: ->
    S4() + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4()

  # Save the current state of the **Store** to *localStorage*.
  save: ->
    localStorage.setItem @name, @records.join(',')

  recordsOn: (key) ->
    store = localStorage.getItem(key)
    (store and store.split(',')) or []

  dirty: (model) ->
    dirtyRecords = @recordsOn @name + '_dirty'
    if not _.include(dirtyRecords, model.id.toString())
      dirtyRecords.push model.id
      localStorage.setItem @name + '_dirty', dirtyRecords.join(',')
    model

  clean: (model, from) ->
    store = "#{@name}_#{from}"
    dirtyRecords = @recordsOn store
    if _.include dirtyRecords, model.id.toString()
      localStorage.setItem store, _.without(dirtyRecords, model.id.toString()).join(',')
    model

  destroyed: (model) ->
    destroyedRecords = @recordsOn @name + '_destroyed'
    if not _.include destroyedRecords, model.id.toString()
      destroyedRecords.push model.id
      localStorage.setItem @name + '_destroyed', destroyedRecords.join(',')
    model

  # Add a model, giving it a unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model) ->
    if not _.isObject(model) then return model
    if not model.id
      model.id = @generateId()
      model.set model.idAttribute, model.id
    localStorage.setItem @name + @sep + model.id, JSON.stringify(model)
    @records.push model.id.toString()
    @save()
    model

  # Update a model by replacing its copy in `this.data`.
  update: (model) ->
    localStorage.setItem @name + @sep + model.id, JSON.stringify(model)
    if not _.include(@records, model.id.toString())
      @records.push model.id.toString()
    @save()
    model

  clear: ->
    for id in @records
      localStorage.removeItem @name + @sep + id
    @records = []
    @save()

  hasDirtyOrDestroyed: ->
    not _.isEmpty(localStorage.getItem(@name + '_dirty')) or not _.isEmpty(localStorage.getItem(@name + '_destroyed'))

  # Retrieve a model from `this.data` by id.
  find: (model) ->
    modelAsJson = localStorage.getItem(@name + @sep + model.id)
    return null if modelAsJson == null
    JSON.parse modelAsJson

  # Return the array of all models currently in storage.
  findAll: ->
    for id in @records
      JSON.parse localStorage.getItem(@name + @sep + id)

  # Delete a model from `this.data`, returning it.
  destroy: (model) ->
    localStorage.removeItem @name + @sep + model.id
    @records = _.reject(@records, (record_id) ->
      record_id is model.id.toString()
    )
    @save()
    model

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

# onlineSyncQueue
onlineSyncQueue = do ->
  tasks = []
  syncInProgress = false
  reset = ->
    tasks = []
    syncInProgress = false
  sync = ->
    nextTask = tasks.shift()
    if nextTask # we have another task in the queue
      syncInProgress = true
      nextTask()
        .done(-> sync())
        .fail(-> reset())
    else # no tasks in the queue
      reset()
  
  queue = 
    length: -> tasks.length
    push: (task) ->
      tasks.push(task)
      sync() unless syncInProgress

# Override `Backbone.sync` to use delegate to the model or collection's
# *localStorage* property, which should be an instance of `Store`.
localsync = (method, model, options) ->
  console.log "CALL: localsync", method, options
  isValidModel = (method is 'clear') or (method is 'hasDirtyOrDestroyed')
  isValidModel ||= model instanceof Backbone.Model
  isValidModel ||= model instanceof Backbone.Collection

  if not isValidModel
    throw new Error 'model parameter is required to be a backbone model or collection.'

  store = new Store options.storeName

  response = switch method
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
      unless options.add and not options.merge and (preExisting = store.find(model))
        model = store.create(model)
        store.dirty(model) if options.dirty
        model
      else
        preExisting
    when 'update'
      store.update(model)
      if options.dirty
        store.dirty(model)
      else
        store.clean(model, 'dirty')
    when 'delete'
      store.destroy(model)
      if options.dirty
        store.destroyed(model)
      else
        if model.id.toString().length == 36
          store.clean(model, 'dirty')
        else
          store.clean(model, 'destroyed')
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

# Right now Backbone.dualStorage infers a model is persisted if
# it's id length is NOT 36 characters
isModelPersisted = (model) ->
  return not (_.isString(model.id) and model.id.length == 36)

isLocallyCached = (storeName) ->
  return localStorage.getItem(storeName);

modelUpdatedWithResponse = (model, response) ->
  modelClone = new Backbone.Model
  modelClone.idAttribute = model.idAttribute
  modelClone.urlRoot = model.collection.url
  modelClone.set model.attributes
  modelClone.set modelClone.parse response
  modelClone

backboneSync = Backbone.sync
onlineSync = (method, model, options) ->
  console.log "CALL: onlineSync", method, model.id
  options.success = callbackTranslator.forBackboneCaller(options.success)
  options.error   = callbackTranslator.forBackboneCaller(options.error)
  backboneSync(method, model, options)

dualsync = (method, model, options) ->
  console.log "CALL: dualsync", method, model.id
  options.storeName = result(model.collection, 'storeName') || result(model, 'storeName') ||
                      result(model.collection, 'url')       || result(model, 'urlRoot')   || result(model, 'url')
  options.success = callbackTranslator.forDualstorageCaller(options.success, model, options)
  options.error   = callbackTranslator.forDualstorageCaller(options.error, model, options)
  
  # execute only online sync
  return onlineSync(method, model, options) if result(model, 'remote') or result(model.collection, 'remote')

  # execute localSyncFirst but skip if 'localFirst' has been explicitly set to false
  # TO DO: This check seems smelly. REFACTOR.
  #if not (result(model, 'localFirst') == false || result(model.collection, 'localFirst') == false)
  return localSyncFirst(method, model, options) if (result(model, 'localFirst') or result(model.collection, 'localFirst'))

  # execute only local sync
  local = result(model, 'local') or result(model.collection, 'local')
  options.dirty = options.remote is false and not local
  return localsync(method, model, options) if options.remote is false or local

  # Execute remoteSyncFirst
  return remoteSyncFirst(method,model,options)

localSyncFirst = (method, model, options) ->
  console.log "CALL: localSyncFirst", method, model.id
  switch method
    when 'read'
      if localsync('hasDirtyOrDestroyed', model, {ignoreCallbacks: true, storeName: options.storeName})
        options.success localsync(method, model, options)
      else
        # helper functions
        storeServerResponse = (resp) ->
          localsyncOptions = _.clone(options)
          localsyncOptions.ignoreCallbacks = true
          resp = parseRemoteResponse(model, resp)
          
          if _.isArray resp
            collection = model
            idAttribute = collection.model.prototype.idAttribute

            # update backbone collection
            backboneModelMethod = if localsyncOptions.reset then 'reset' else 'set'
            collection[backboneModelMethod](resp, options);

            localsync('clear', model, localsyncOptions)
            for model in collection.models
              localsync 'create', model, localsyncOptions
          else
            model[backboneModelMethod](resp, options)
            localsync('clear', model, localsyncOptions)
            localsync 'create', model, localsyncOptions

          model.trigger('sync', model, resp, options);

        onlineSyncSuccess = (resp, status, xhr) ->
          storeServerResponse resp, status, xhr
          options.success resp, status, xhr
        
        # online sync and then save to local store if no data is locally available
        if not isLocallyCached options.storeName
          return onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: onlineSyncSuccess
        

        # localsync setup
        localsyncOptions = _.clone(options)

        # localsync callbacks
        localsyncOptions.success = (resp, status, xhr) ->
          options.success resp, status, xhr
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: storeServerResponse
        
        localsyncOptions.error = (resp, status, xhr) ->
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: onlineSyncSuccess
     
        # Do the sync
        localsync(method, model, localsyncOptions)

    when 'create'
      # helper functions
      storeServerResponse = (resp, status, xhr) ->
        localsyncOptions = _.clone(options)
        localsyncOptions.ignoreCallbacks = true
        
        # delete the old model
        localsync('delete', model, localsyncOptions) 
        
        # parse the response
        resp = parseRemoteResponse(model, resp)
        
        # refresh the model with the response
        options.success(resp)

        # save the new model to the local store
        localsync(method, model, localsyncOptions)

      onlineSyncSuccess = (resp, status, xhr) ->
        storeServerResponse resp, status, xhr
        options.success resp, status, xhr

      # localsync setup
      localsyncOptions = _.clone(options)
      localsyncOptions.dirty = true

      # localsync callbacks
      localsyncOptions.success = (resp, status, xhr) ->
        options.success resp, status, xhr
        # make sure the original model doesn't have an id set to make #isNew() true.
        modelToSend = modelUpdatedWithResponse model, resp
        modelToSend.set model.idAttribute, null, silent: true
        
        onlineSyncQueue.push do (method, model) -> 
          -> onlineSync method, modelToSend, success: storeServerResponse
      localsyncOptions.error = (resp, status, xhr) ->
        onlineSyncQueue.push do (method, model) -> 
          -> onlineSync method, model, success: onlineSyncSuccess
   
      # Do the sync
      localsync(method, model, localsyncOptions)
    
    when 'update'
      # helper functions
      storeServerResponseAndUpdateModel = (resp) ->
        localsyncOptions = _.clone(options)
        localsyncOptions.ignoreCallbacks = true
        
        # delete the old model
        localsync('delete', model, localsyncOptions) if deleteLocal

        # parse the response
        resp = parseRemoteResponse(model, resp)
        
        # refresh the model with the response
        options.success(resp)

        # save the new model to the local store
        localsync(method, model, localsyncOptions)

      onlineSyncSuccess = (resp, status, xhr) ->
        storeServerResponseAndUpdateModel resp, status, xhr
        options.success resp, status, xhr

      # localsync setup
      localsyncOptions = _.clone(options)
      localsyncOptions.dirty = true
      deleteLocal = false;

      if isModelPersisted(model)
      
        # localsync callbacks
        localsyncOptions.success = (resp, status, xhr) ->
          options.success resp, status, xhr
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: storeServerResponseAndUpdateModel
        localsyncOptions.error = (resp, status, xhr) ->
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: onlineSyncSuccess
      
      else # Model is not persisted on server
      
        # localsync callbacks
        localsyncOptions.success = (resp, status, xhr) ->
          options.success resp, status, xhr
          
          # make sure that the temp model is deleted from the local store
          deleteLocal = true;

          # make sure the original model doesn't have an id set to make #isNew() true.
          modelToSend = modelUpdatedWithResponse model, resp
          modelToSend.set model.idAttribute, null, silent: true
          
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, modelToSend, success: storeServerResponseAndUpdateModel
        localsyncOptions.error = (resp, status, xhr) ->
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: onlineSyncSuccess
      
      # Do the sync
      localsync(method, model, localsyncOptions)

    when 'delete'
    
      # Cache the model's urlRoot computed from collection as the model will not be a part of the collection during online sync.
      url = model.url()

      # helper functions
      storeServerResponse = (resp) ->
        localsyncOptions = _.clone(options)
        localsyncOptions.ignoreCallbacks = true
        localsyncOptions.dirty = false
        localsync('delete', model, localsyncOptions)     
      onlineSyncSuccess = (resp, status, xhr) ->
        storeServerResponse resp, status, xhr
        options.success resp, status, xhr

      # localsync setup
      localsyncOptions = _.clone(options)
      localsyncOptions.dirty = true

      model.url = url;

      if isModelPersisted(model)
      
        # localsync callbacks
        localsyncOptions.success = (resp, status, xhr) ->
          options.success resp, status, xhr
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: storeServerResponse
        localsyncOptions.error = (resp, status, xhr) ->
          onlineSyncQueue.push do (method, model) -> 
            -> onlineSync method, model, success: onlineSyncSuccess
      
      else # Model is not persisted on server
      
        # localsync callbacks
        localsyncOptions.success = (resp, status, xhr) ->
          options.success resp, status, xhr
        localsyncOptions.error = (resp, status, xhr) ->
          message = "Backbone.dualStorage: localSyncFirst DELETE failed."
          console.error message
          options.error message: message

      # Do the sync
      _.defer localsync, method, model, localsyncOptions
      

remoteSyncFirst = (method, model, options) ->
  console.log "CALL: remoteSyncFirst", method, model.id
  # execute standard dual sync
  options.ignoreCallbacks = true

  success = options.success
  error = options.error

  switch method
    when 'read'
      if localsync('hasDirtyOrDestroyed', model, options)
        success localsync(method, model, options)
      else
        options.success = (resp, status, xhr) ->
          resp = parseRemoteResponse(model, resp)

          localsync('clear', model, options) unless options.add

          if _.isArray resp
            collection = model
            idAttribute = collection.model.prototype.idAttribute
            for modelAttributes in resp
              model = collection.get(modelAttributes[idAttribute])
              if model
                responseModel = modelUpdatedWithResponse(model, modelAttributes)
              else
                responseModel = new collection.model(modelAttributes)
              localsync('create', responseModel, options)
          else
            responseModel = modelUpdatedWithResponse(model, resp)
            localsync('create', responseModel, options)

          success(resp, status, xhr)

        options.error = (resp) ->
          success localsync(method, model, options)

        onlineSync(method, model, options)

    when 'create'
      options.success = (resp, status, xhr) ->
        updatedModel = modelUpdatedWithResponse model, resp
        localsync(method, updatedModel, options)
        success(resp, status, xhr)
      options.error = (resp) ->
        options.dirty = true
        success localsync(method, model, options)

      onlineSync(method, model, options)

    when 'update'
      if _.isString(model.id) and model.id.length == 36
        temporaryId = model.id

        options.success = (resp, status, xhr) ->
          updatedModel = modelUpdatedWithResponse model, resp
          model.set model.idAttribute, temporaryId, silent: true
          localsync('delete', model, options)
          localsync('create', updatedModel, options)
          success(resp, status, xhr)
        options.error = (resp) ->
          options.dirty = true
          model.set model.idAttribute, temporaryId, silent: true
          success localsync(method, model, options)

        model.set model.idAttribute, null, silent: true
        onlineSync('create', model, options)
      else
        options.success = (resp, status, xhr) ->
          updatedModel = modelUpdatedWithResponse model, resp
          localsync(method, updatedModel, options)
          success(resp, status, xhr)
        options.error = (resp) ->
          options.dirty = true
          success localsync(method, model, options)

        onlineSync(method, model, options)

    when 'delete'
      if _.isString(model.id) and model.id.length == 36
        localsync(method, model, options)
      else
        options.success = (resp, status, xhr) ->
          localsync(method, model, options)
          success(resp, status, xhr)
        options.error = (resp) ->
          options.dirty = true
          success localsync(method, model, options)

        onlineSync(method, model, options)

Backbone.sync = dualsync
