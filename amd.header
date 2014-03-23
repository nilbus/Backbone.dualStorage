(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    return define(['backbone'], function(Backbone) {
      return root.Backbone.DualStorage = factory(Backbone);
    });
  } else if (typeof require === 'function' && ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null)) {
    return module.exports = factory(require('backbone'));
  } else {
    return root.Backbone.DualStorage = factory(root.Backbone);
  }
})(this, function(Backbone) {
