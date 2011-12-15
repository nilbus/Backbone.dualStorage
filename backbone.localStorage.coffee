S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

guid = ->
  S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()

class window.Store
  constructor: (name) ->
    @name = name
    store = localStorage.getItem(@name)
    @records = (store and store.split(",")) or []

  save: ->
    localStorage.setItem @name, @records.join(",")

  create: (model) ->
    model.id = model.attributes.id = guid()  unless model.id
    localStorage.setItem @name + "-" + model.id, JSON.stringify(model)
    @records.push model.id.toString()
    @save()
    model

  update: (model) ->
    localStorage.setItem @name + "-" + model.id, JSON.stringify(model)
    @records.push model.id.toString()  unless _.include(@records, model.id.toString())
    @save()
    model

  find: (model) ->
    JSON.parse localStorage.getItem(@name + "-" + model.id)

  findAll: ->
    _.map @records, ((id) ->
      JSON.parse localStorage.getItem(@name + "-" + id)
    ), this

  destroy: (model) ->
    localStorage.removeItem @name + "-" + model.id
    @records = _.reject(@records, (record_id) ->
      record_id is model.id.toString()
    )
    @save()
    model

Backbone.sync = (method, model, options, error) ->
  if typeof options is "function"
    options =
      success: options
      error: error
  resp = undefined
  store = model.localStorage or model.collection.localStorage
  switch method
    when "read"
      resp = (if model.id then store.find(model) else store.findAll())
    when "create"
      resp = store.create(model)
    when "update"
      resp = store.update(model)
    when "delete"
      resp = store.destroy(model)
  if resp
    options.success resp
  else
    options.error "Record not found"