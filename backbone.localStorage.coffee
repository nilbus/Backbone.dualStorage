###
 * Backbone localStorage Adapter v1.0
 * https://github.com/jeromegn/Backbone.localStorage
 *
 * Date: Sun Aug 14 2011 09:53:55 -0400
###

# A simple module to replace `Backbone.sync` with *localStorage*-based
# persistence. Models are given GUIDS, and saved into a JSON object. Simple
# as that.

# Generate four random hex digits.
S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

# Generate a pseudo-GUID by concatenating random hexadecimal.
guid = ->
  S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
class window.Store
  constructor: (name) ->
    @name = name
    store = localStorage.getItem(@name)
    @records = (store and store.split(",")) or []

  # Save the current state of the **Store** to *localStorage*.
  save: ->
    localStorage.setItem @name, @records.join(",")

  # Add a model, giving it a (hopefully)-unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model) ->
    model.id = model.attributes.id = guid()  unless model.id
    localStorage.setItem @name + "-" + model.id, JSON.stringify(model)
    @records.push model.id.toString()
    @save()
    model

  # Update a model by replacing its copy in `this.data`.
  update: (model) ->
    localStorage.setItem @name + "-" + model.id, JSON.stringify(model)
    @records.push model.id.toString()  unless _.include(@records, model.id.toString())
    @save()
    model

  # Retrieve a model from `this.data` by id.
  find: (model) ->
    JSON.parse localStorage.getItem(@name + "-" + model.id)

  # Return the array of all models currently in storage.
  findAll: ->
    _.map @records, ((id) ->
      JSON.parse localStorage.getItem(@name + "-" + id)
    ), this

  # Delete a model from `this.data`, returning it.
  destroy: (model) ->
    localStorage.removeItem @name + "-" + model.id
    @records = _.reject(@records, (record_id) ->
      record_id is model.id.toString()
    )
    @save()
    model

# Override `Backbone.sync` to use delegate to the model or collection's
# *localStorage* property, which should be an instance of `Store`.
Backbone.sync = (method, model, options, error) ->
  # Backwards compatibility with Backbone <= 0.3.3
  if typeof options is "function"
    options =
      success: options
      error: error

  store = model.localStorage or model.collection.localStorage

  resp = switch method
    when "read"
      if model.id then store.find(model) else store.findAll()
    when "create"
      store.create(model)
    when "update"
      store.update(model)
    when "delete"
      store.destroy(model)

  if resp
    options.success resp
  else
    options.error "Record not found"