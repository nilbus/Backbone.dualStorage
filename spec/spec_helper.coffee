window.Backbone.sync = jasmine.createSpy('sync').andCallFake (method, model, options) ->
  model.updatedByRemoteSync = true
  resp = options.serverResponse || model.toJSON()
  if Backbone.VERSION == '0.9.10'
    options.success(model, resp, options)
  else
    options.success(resp, 200, {})
