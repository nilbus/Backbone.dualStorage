sinon.stub window.Backbone, 'sync', (method, model, options) ->
  model.updatedByRemoteSync = true
  resp = options.serverResponse || model.toJSON()
  status = 200
  callback = options.success
  xhr = {status: status, response: resp}
  if typeof options.errorStatus is 'number'
    resp.status = status = options.errorStatus
    callback = options.error
  callbackWithVersionedArgs = ->
    if Backbone.VERSION == '0.9.10'
      callback(model, resp, options)
    else if Backbone.VERSION[0] == '0'
      callback(resp, status, xhr)
    else
      options.xhr = xhr
      callback(resp)
  # Force async response to simulate real ajax
  setTimeout callbackWithVersionedArgs, 0
  xhr
