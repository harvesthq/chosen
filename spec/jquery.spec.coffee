# The most basic test
fw_basictest = () ->
  it "should add chosen to jQuery object", ->
    do expect(jQuery.fn.chosen).toBeDefined

# A wrapper around needed "framework"-functions, so we can use the same jasmine
# tests for jquery and prototype
fw = (el) ->
  {
    # the actual element
    dom_el: el
    
    # some common dom traversal functions
    find: (q) -> #Return an array of fw's
      ret = []
      $(el).find(q).each -> ret.push fw(this)
      ret

    # other functions needed during testing
    hasClass: (clazz) -> $(el).hasClass clazz
    trigger: (evt) -> $(el).trigger evt
    val: (v) -> if v? then $(el).val v else do $(el).val
    text: () -> do $(el).text
    html: (v) -> if v? then $(el).html v else do $(el).html
    onEvt: (evt, fn) -> $(el).on evt, fn
  }

fw_testcase = (tmpl, settings = {}) ->
  # Wrap each test in a div and put the "template" in it
  # (usually just the select itself)
  div = $("<div>").html tmpl
  
  # Find the select
  select = div.find "select"
  
  # Create the Chosen instance - possibly with specific settings for this "case"
  select.chosen settings
  
  # Return an object that has easy access (through the "framework wrapper") to
  # the elements
  {
    div: fw div[0]
    select: fw select[0]
    container: fw div.find(".chosen-container")[0]
    search_field: fw(div.find(".chosen-search input")[0] or div.find(".chosen-search-input")[0])
  }