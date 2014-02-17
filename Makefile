compile:
	coffee -c backbone.dualstorage.coffee spec/*.coffee
	coffee -cbo spec backbone.dualstorage.coffee
	cat amd.header.js spec/backbone.dualstorage.js amd.footer.js > backbone.dualstorage.amd.js

watch:
	coffee -wc backbone.dualstorage.coffee spec/*.coffee
	coffee -wcbo spec backbone.dualstorage.coffee
