compile:
	coffee -c backbone.dualstorage.coffee spec/*.coffee
	cat amd.header.js > backbone.dualstorage.amd.js
	coffee -cbp backbone.dualstorage.coffee >> backbone.dualstorage.amd.js
	cat amd.footer.js >> backbone.dualstorage.amd.js
	coffee -cbo spec backbone.dualstorage.coffee

infinite: compile
	read # (press Enter to recompile)
	make infinite
