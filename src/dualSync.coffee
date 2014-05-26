# Backbone.sync replacement for dual data persistance

updateModelWithResponse = (model, response) ->
  modelClone = new Backbone.Model
  modelClone.idAttribute = model.idAttribute
  modelClone.set model.attributes
  modelClone.set modelClone.parse response
  modelClone

onlineSync = Backbone.sync

dualSync = (method, model, options) ->
  options.storeName = _.result(model.collection, 'storeName') or
                      _.result(model, 'storeName') or
                      _.result(model.collection, 'url') or
                      _.result(model, 'urlRoot') or
                      _.result(model, 'url')

  if _.result(model, 'onlyRemote') or _.result(model.collection, 'onlyRemote')
    return onlineSync(method, model, options)

  onlyLocal = _.result(model, 'onlyLocal') or _.result(model.collection, 'onlyLocal')
  options.offline = not onlyLocal and options.remote == false
  if onlyLocal or options.remote == false
    return localSync(method, model, options).done (response) ->
      options?.success model, response, options

  # TODO: implement parseBeforeLocalSave
  success = options.success
  error = options.error

  switch method
    when 'read'
      localSync('hasDirtyOrDestroyed', model, options).then (hasDirtyOrDestroyed) ->
        if hasDirtyOrDestroyed
          # The store has dirty or destroyed models, return local data only.
          return localSync('read', model, options).done (response) ->
            options?.success model, response, options
        else
          # Run onlineSync and then save models locally.
          returnModel = model
          options.success = (model, response, options) ->
            models = []
            if _.isArray response
              collection = model
              idAttribute = collection.model.prototype.idAttribute
              for modelAttributes in response
                model = collection.get(modelAttributes[idAttribute])
                model and model = updateModelWithResponse(model, modelAttributes)
                if not model
                  model = new collection.model(modelAttributes)
                models.push model
            else
              models = [updateModelWithResponse(model, response)]

            if not options.add
              promise = localSync('clear', model, options)
            else
              promise = $.Deferred().resolve()

            promise.done = ->
              promises = (localSync('create', model, options) for model in models)
              $.when(promises...).then ->
                success? returnModel, response, options

          # On read error, return local models
          options.error = (model, response, options) ->
            localSync('read', model, options).then (response) ->
              success? model, response, options

          onlineSync 'read', model, options

    when 'create'
      options.success = (model, response, options) ->
        updatedModel = updateModelWithResponse model, response
        localSync('create', updatedModel, options).then (savedModel) ->
          success? model, savedModel.attributes, options

      options.error = (model, response, options) ->
        options.offline = true
        localSync('create', model, options).then (savedModel) ->
          success? model, savedModel.attributes, options

      onlineSync 'create', model, options

    when 'update'
      # TODO: use localSync and check if model is in local list
      # instead of checking id length.

      if model?.id.length == 36
        temporaryId = model.id

        options.success = (model, response, options) ->
          updatedModel = updateModelWithResponse model, response
          model.set model.idAttribute, temporaryId, silent: true
          localSync('remove', model, options).then ->
            localSync('create', updatedModel, options).then (savedModel)->
              success? savedModel, savedModel.attributes, options

        options.error = (model, response, options) ->
          options.offline = true
          model.set model.idAttribute, temporaryId, silent: true
          localSync('update', model, options).then (savedModel) ->
            success? savedModel, savedModel.attributes, options

        model.set model.idAttribute, null, silent: true
        onlineSync 'create', model, options

      else
        options.success = (model, response, options) ->
          updatedModel = updateModelWithResponse model, response
          localSync('update', updatedModel, options).then ->
            success? model, response, options

        options.error = (model, response, options) ->
          options.offline = true
          localSync('update', model, options).then ->
            success? model, response, options

        onlineSync 'update', model, options

    when 'remove'
      if model?.id.length == 36
        localSync 'remove', model, options
      else
        options.success = (model, response, options) ->
          localSync('remove', model, options).then ->
            success? model, response, options

        options.error = (model, response, options) ->
          options.offline = true
          localSync('remove', model, options).then ->
            success? model, response, options

        onlineSync 'remove', model, options


Backbone.onlineSync = onlineSync
Backbone.dualSync = dualSync
