compile:
	coffee -mcj backbone.dualstorage.js backbone.dualstorage.adapters.coffee backbone.dualstorage.coffee
	coffee -mc spec/*.coffee
	coffee -mcbj spec/backbone.dualstorage.js backbone.dualstorage.adapters.coffee backbone.dualstorage.coffee
	cat amd.header backbone.dualstorage.js amd.footer > backbone.dualstorage.amd.js

watch:
	coffee -wmcj backbone.dualstorage.js backbone.dualstorage.adapters.coffee backbone.dualstorage.coffee &
	coffee -wmc spec/*.coffee &
	coffee -wmcbj spec/backbone.dualstorage.js backbone.dualstorage.adapters.coffee backbone.dualstorage.coffee &
	# Press ^C to exit
	while true; do sleep 100; done
