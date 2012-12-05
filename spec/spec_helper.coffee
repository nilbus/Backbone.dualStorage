vm = require 'vm'
fs = require 'fs'
coffee = require 'coffee-script'
backboneDualstoragePath = './backbone.dualstorage.coffee'
source = fs.readFileSync(backboneDualstoragePath, 'utf8')
window = require('./global_test_context.coffee').window
context = vm.createContext window
coffee.eval source, sandbox: context, filename: backboneDualstoragePath
exports.window = context
