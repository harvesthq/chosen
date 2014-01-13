YUI.add 'chosen-yui', (Y, name) ->

  Y.Node.addMethod "chosen", (options) ->
    node = this.getDOMNode()
    if node.nodeName is "SELECT" and AbstractChosen.browser_is_supported()
      chosen = this.getData 'chosen'
      if options is 'destroy' && chosen
        chosen.destroy()
      else unless chosen
        this.setData 'chosen', new Chosen(node, options)
    return

, '0.0.1', requires: ['node']