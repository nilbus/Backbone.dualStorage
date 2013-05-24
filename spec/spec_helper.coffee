window.Backbone.sync = jasmine.createSpy('sync').andCallFake (method, model, options) ->
  model.updatedByRemoteSync = true
  if Backbone.VERSION == '0.9.10'
    resp = model
    options.success(model, resp, options)
  else
    options.success(model.toJSON(), 200, {})
