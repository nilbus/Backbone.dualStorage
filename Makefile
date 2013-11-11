compile:
	coffee -c backbone.dualstorage.coffee spec/*.coffee
	coffee -cbo spec backbone.dualstorage.coffee
	cat amd.header.js spec/backbone.dualstorage.js amd.footer.js > backbone.dualstorage.amd.js

infinite: compile
	read # (press Enter to recompile)
	make infinite
