# Wrapper function with Backbone.sync API for persisting data in a *storage*
# (through a Backbone.Store instance)

localSync = (method, model, options) ->
  isValidModel = method in ['clear', 'hasDirtyOrDestroyed']
  isValidModel ||= model instanceof Backbone.Model
  isValidModel ||= model instanceof Backbone.Collection

  if not isValidModel
    throw new Error 'model parameter is required to be a Backbone model or collection.'

  if not options.storeName
    throw new Error 'storeName parameter is required.'

  if not options.storage
    throw new Error 'storage parameter is required.'

  # Helpers method to return sync methods as async promises
  returnAsync = -> $.Deferred().resolve

  store = new Backbone.Store options.storeName, options.storage

  store.initialize().then ->
    promise = switch method
      when 'read'
        returnAsync store.find model?.id

      when 'create'
        store.add(model).then (model) ->
          store.isDirty(model, options.offline)

      when 'update'
        store.update(model).then (model) ->
          store.isDirty(model, options.offline)

      when 'remove'
        store.remove(model).then (model) ->
          store.isDestroyed(model, options.offline)

      when 'clear'
        store.clear()

      when 'hasDirtyOrDestroyed'
        returnAsync store.hasDirtyOrDestroyed()

    if options.useCallbacks
      promise.done (response) ->
        options.success response?.attributes or response
