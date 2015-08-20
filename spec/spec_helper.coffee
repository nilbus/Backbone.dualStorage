sinon.stub window.Backbone, 'sync', (method, model, options) ->
  model.updatedByRemoteSync = true
  resp = options.serverResponse || model.toJSON()
  status = 200
  callback = options.success
  xhr = $.extend($.Deferred(), status: status, response: resp)
  isError = typeof options.errorStatus is 'number'
  if isError
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
    if isError
      xhr.reject()
    else
      xhr.resolve()
  # Force async response to simulate real ajax
  setTimeout callbackWithVersionedArgs, 0
  xhr
