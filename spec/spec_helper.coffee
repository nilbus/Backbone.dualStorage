window.Backbone.sync = jasmine.createSpy('sync').andCallFake (method, model, options) -> options.success(model)
