vm = require 'vm'
fs = require 'fs'
coffee = require 'coffee-script'
backbone_dualstorage_path = './backbone.dualstorage.coffee'
source = fs.readFileSync(backbone_dualstorage_path, 'utf8')
window = require('./global_test_context.coffee').window
context = vm.createContext window
coffee.eval source, sandbox: context, filename: backbone_dualstorage_path
exports.window = context
