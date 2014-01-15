compile:
	coffee -cj backbone.dualstorage.js backbone.dualstorage.adapters.coffee backbone.dualstorage.coffee
	coffee -c spec/*.coffee
	coffee -cbj spec/backbone.dualstorage.js backbone.dualstorage.adapters.coffee backbone.dualstorage.coffee
	cat amd.header.js backbone.dualstorage.js amd.footer.js > backbone.dualstorage.amd.js

infinite: compile
	read # (press Enter to recompile)
	make infinite
