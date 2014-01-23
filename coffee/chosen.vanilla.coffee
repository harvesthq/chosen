Element.prototype.chosen = (options) ->
  if this.nodeName is "SELECT" and AbstractChosen.browser_is_supported()
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    # Continue on if running IE document type but in compatibility mode
    chosen = this.getAttribute 'data-chosen'
    if options is 'destroy' && chosen
      chosen.destroy()
    else unless chosen
      this.setAttribute 'data-chosen', new Chosen(this, options)
  return