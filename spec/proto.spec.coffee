# The most basic test
fw_basictest = () ->
  it "should expose a Chosen global", ->
    do expect(Chosen).toBeDefined

# A wrapper around needed "framework"-functions, so we can use the same jasmine
# tests for jquery and prototype
fw = (el) ->
  {
    # the actual element
    dom_el: el
    
    # some common dom traversal functions
    find: (q) -> #Return an array of fw's
      ret = []
      for elm in el.select(q)
        ret.push fw(elm)
      ret
    
    # other functions needed during testing
    hasClass: (clazz) -> el.hasClassName clazz
    trigger: (evt) -> simulant.fire el, evt
    val: (v) -> if v? then el.value = v else $F el
    text: () -> el.innerText || el.textContent
    html: (v) -> if v? then el.innerHTML = v else el.innerHTML
    onEvt: (evt, fn) -> el.addEventListener evt, fn
  }

fw_testcase = (tmpl, settings = {}) ->
  # Wrap each test in a div
  div = new Element "div"
  document.body.insert div
  
  # Put the "template" in the div (usually just the select itself)
  div.update tmpl
  
  # Find the select
  select = div.down "select"
  
  # Create the Chosen instance - possibly with specific settings for this "case"
  new Chosen select, settings
  
  # Find some elements that are needed for many tests
  container = div.down ".chosen-container"
  search_field = div.down(".chosen-search input") or div.down(".chosen-search-input")
  
  # Return an object that has easy access (through the "framework wrapper") to
  # the elements
  {
    div: fw div
    select: fw select
    container: fw container
    search_field: fw search_field
  }