((root, factory) ->
  chosen = (jQuery, elementOrQuery, options) ->
    $ = jQuery
    query = $ elementOrQuery

    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    # Continue on if running IE document type but in compatibility mode
    return query if $.browser.msie and ($.browser.version is "6.0" or  ($.browser.version is "7.0" and document.documentMode is 7 ))
    
    Chosen = factory($)
    query.each(() ->
      $this = $ this
      $this.data('chosen', new Chosen(this, options)) unless $this.hasClass "chzn-done"
    )

  if define? and define.amd
    define 'chosen', [ 'jquery' ], (jQuery) ->
      (elementOrQuery, options) ->
        chosen jQuery, elementOrQuery, options
  else
    $ = root.jQuery
    $.fn.extend({
      chosen: (options) ->
        chosen $, this, options
    })
)(this, (jQuery) ->
  'select_parser'
  'abstract_chosen'
  'chosen_jquery'
  this.Chosen
)