# Async store class for saving a collection of models in a *storage*.
# It also handles saving dirty and destroyed metadata.

# Store only provides an API for saving models and dirty/destroyed metadata,
# without actually knowing when it should save the model as dirty/destroyed or
# when to remove it from those lists.
# That is handled at a higher level (in localSync/dualSync).

class Backbone.Store
  constructor: (name, storage) ->
    @name = name
    @storage = storage
    @data = {}

  # Generates a unique id to use when saving new instances while offline.
  # By default generates a pseudo-GUID by concatenating random hexadecimal.
  # You can overwrite this function to use another strategy.
  generateId: ->
    S4() + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4()

  # Load the current state of the Store from storage.
  initialize: ->
    @storage.get(@name).then (savedData) =>
      # All models currently available in this store.
      @data.records = savedData?.records || []
      # Models that have been modified and need to sync online.
      @data.dirty = savedData?.dirty || []
      # Models that have been destroyed and need to sync online.
      @data.destroyed = savedData?.destroyed || []
      # Models that are only saved locally.
      # If the model is not in the dirty list, then it is a local only model.
      @data.local = savedData?.local || []
      # Map ids to model attributes.
      @data.recordsById = savedData?.recordsById || {}

  # Save the current state of the Store in storage.
  save: ->
    @storage.set @name, @data

  # Add or remove a model from dirty or destroyed arrays.
  # TODO: find a better name for this method?
  toggleModel: (target, model, status) ->
    if status and model.id not in @data[target]
      @data[target].push model.id
    else if not status and model.id in @data[target]
      @data[target] = _.without @data[target], model.id

    @save().then -> model

  # Mark a model as dirty / not dirty.
  isDirty: (model, status) ->
    if model.id not in @data.records
      throw new Error "model with id #{model.id} is not in the store."

    if model.id in @data.destroyed
      throw new Error "can't mark model with id #{model.id} as dirty because it is marked as destroyed."

    @toggleModel 'dirty', model, status

  # Mark a model as destroyed / not destroyed.
  isDestroyed: (model, status) ->
    if model.id in @data.records
      throw new Error "can't mark model with id #{model.id} as destroyed because it is still in the store."

    if model.id in @data.dirty
      throw new Error "can't mark model with id #{model.id} as destroyed because it is marked as dirty."

    @toggleModel 'destroyed', model, status

  # Add a model to the store.
  add: (models) ->
    models = [models] if not _.isArray models
    for model in models
      if model.id in @data.records
        throw new Error "model with id #{model.id} is already in the store."

      # If id is missing, then we add it as a local model.
      # This could be because the client if offline, server responded with error,
      # or the model is configured to save only locally.
      if not model.id
        model.id = @generateId()
        model.set model.idAttribute, model.id
        @data.local.push model.id

      @data.records.push model.id
      @data.recordsById[model.id] = model.toJSON()

    @save().then -> if models.length == 1 then models[0] else models

  # Update a model in the store.
  update: (model) ->
    if not model.id
      throw new Error "model does not have an id."

    if model.id not in @data.records
      throw new Error "model with id #{model.id} is not in the store, try adding instead of updating."

    @data.recordsById[model.id] = model.toJSON()
    @save().then -> model

  # Remove a model from the store.
  remove: (model) ->
    delete @data.recordsById[model.id]
    @data.dirty = _.without @data.dirty, model.id
    @data.local = _.without @data.local, model.id
    @data.records = _.without @data.records, model.id
    @save().then -> model

  # Clear all models in the store.
  clear: ->
    @data = {}
    @save()

  # Retrieve a model from the store by id.
  # Or return all models if id is falsy.
  find: (id) ->
    if id then @data.recordsById[id]
    else (model for id, model of @data.recordsById)

  # Retrieve all dirty models.
  findDirty: (id) ->
    if id
      @data.recordsById[id] if id in @data.dirty
    else
      (@data.recordsById[id] for id in @data.dirty)

  # Retrieve all destroyed model ids.
  findDestroyed: (id) ->
    if id then id in @data.destroyed
    else @data.destroyed

  # Returns true if there are dirty or destroyed models in the store.
  hasDirtyOrDestroyed: ->
    not _.isEmpty(@data.dirty) or not _.isEmpty(@data.destroyed)


# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
