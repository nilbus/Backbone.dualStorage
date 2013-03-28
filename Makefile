compile:
	coffee -c backbone.dualstorage.coffee spec/*.coffee
	coffee -cbo spec backbone.dualstorage.coffee

infinite: compile
	read # (press Enter to recompile)
	make infinite
