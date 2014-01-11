window.YUI.add 'test', (Y, name) ->
  Y.Test = Y.Base.create 'test', Y.Base, [Y.Lib],
    initializer: (cfg) ->
      myFirstMethod: ->
  , ATTRS:
      myFirstAttribute: {}
  return

, '0.0.1', requires: []