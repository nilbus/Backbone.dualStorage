compile:
	coffee -mc backbone.dualstorage.coffee spec/*.coffee
	coffee -mcbo spec backbone.dualstorage.coffee
	cat amd.header spec/backbone.dualstorage.js amd.footer > backbone.dualstorage.amd.js

watch:
	coffee -wmc backbone.dualstorage.coffee spec/*.coffee &
	coffee -wmcbo spec backbone.dualstorage.coffee &
	# Press ^C to exit
	while true; do sleep 100; done
