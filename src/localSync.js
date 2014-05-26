// Generated by CoffeeScript 1.6.3
var localSync;

localSync = function(method, model, options) {
  var isValidModel, returnAsync, store;
  isValidModel = method === 'clear' || method === 'hasDirtyOrDestroyed';
  isValidModel || (isValidModel = model instanceof Backbone.Model);
  isValidModel || (isValidModel = model instanceof Backbone.Collection);
  if (!isValidModel) {
    throw new Error('model parameter is required to be a Backbone model or collection.');
  }
  if (!options.storeName) {
    throw new Error('storeName parameter is required.');
  }
  if (!options.storage) {
    throw new Error('storage parameter is required.');
  }
  returnAsync = function() {
    return $.Deferred().resolve;
  };
  store = new Backbone.Store(options.storeName, options.storage);
  return store.initialize().then(function() {
    var promise;
    promise = (function() {
      switch (method) {
        case 'read':
          return returnAsync(store.find(model != null ? model.id : void 0));
        case 'create':
          return store.add(model).then(function(model) {
            return store.isDirty(model, options.offline);
          });
        case 'update':
          return store.update(model).then(function(model) {
            return store.isDirty(model, options.offline);
          });
        case 'remove':
          return store.remove(model).then(function(model) {
            return store.isDestroyed(model, options.offline);
          });
        case 'clear':
          return store.clear();
        case 'hasDirtyOrDestroyed':
          return returnAsync(store.hasDirtyOrDestroyed());
      }
    })();
    if (options.useCallbacks) {
      return promise.done(function(response) {
        return options.success((response != null ? response.attributes : void 0) || response);
      });
    }
  });
};
