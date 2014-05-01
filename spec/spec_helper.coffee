window.Backbone.sync = jasmine.createSpy('sync').andCallFake (method, model, options) ->
  model.updatedByRemoteSync = true
  resp = options.serverResponse || model.toJSON()
  status = 200
  callback = options.success
  if typeof options.errorStatus is 'number'
    resp.status = status = options.errorStatus
    callback = options.error
  if Backbone.VERSION == '0.9.10'
    callback(model, resp, options)
  else
    callback(resp, status, {})
