desc 'cake test'
task 'default', ->
  jake.Task['test'].invoke()

desc 'Run the tests for Backbone.dualStorage'
task 'test', ->
  @addListener 'error', (error) ->
    console.log 'Error occurred in "test" task:'
    console.log error.message
    console.log "at #{error.fileName}:#{error.lineNumber}" if error.fileName || error.lineNumbers
  jasmine = require 'jasmine-node'
  jasmine.executeSpecsInFolder(
    'spec'            # specFolder
    ->                # onComplete
    false             # isVerbose
    true              # showColors
    false             # teamcity
    false             # useRequireJs
    /^[^.].*spec\.coffee/  # spec matcher
    report: false     # junitreport
  )
