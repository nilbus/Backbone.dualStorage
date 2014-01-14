var StickyStorageAdapter = (function() {
    function StickyStorageAdapter() {}

    StickyStorageAdapter.prototype.initialize = function() {
        var promise = $.Deferred();
        this.store = new StickyStore({
            name: 'Backbone.dualStorage',
            adapters: ['indexedDB', 'webSQL', 'localStorage'],
            ready: function () {
                promise.resolve();
            }
        });
        return promise;
    };

    StickyStorageAdapter.prototype.setItem = function(key, value) {
        var promise = $.Deferred();
        this.store.set(key, value, function (storedValue) {
            promise.resolve(storedValue);
        });
        return promise;
    };

    StickyStorageAdapter.prototype.getItem = function(key) {
        var promise = $.Deferred();
        this.store.get(key, function (storedValue) {
            promise.resolve(storedValue);
        });
        return promise;
    };

    StickyStorageAdapter.prototype.removeItem = function(key) {
        var promise = $.Deferred();
        this.store.remove(key, function () {
            promise.resolve();
        });
        return promise;
    };

    return StickyStorageAdapter;
})();

var LawnchairAdapter = (function() {
    function LawnchairAdapter() {}

    LawnchairAdapter.prototype.initialize = function() {
        var promise = $.Deferred();
        this.store = new Lawnchair({
            name: 'Backbone.dualStorage',
            adapter: ['indexed-db', 'webkit-sqlite', 'dom']
        }, function () {
            promise.resolve();
        });
        return promise;
    };

    LawnchairAdapter.prototype.setItem = function(key, value) {
        var promise = $.Deferred();
        this.store.save({key: value}, function () {
            promise.resolve(value);
        });
        return promise;
    };

    LawnchairAdapter.prototype.getItem = function(key) {
        var promise = $.Deferred();
        this.store.get(key, function (storedValue) {
            promise.resolve(storedValue);
        });
        return promise;
    };

    LawnchairAdapter.prototype.removeItem = function(key) {
        var promise = $.Deferred();
        this.store.remove(key, function () {
            promise.resolve();
        });
        return promise;
    };

    return LawnchairAdapter;
})();