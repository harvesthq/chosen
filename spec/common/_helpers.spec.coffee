# Helper to distinguish arrays from other objects
type_is_array = Array.isArray || (value) -> {}.toString.call( value ) is '[object Array]'

# Helper to determine if a variable is a dom element
type_is_dom_elm = (el) -> typeof el is 'object' and el.style?

# Helper to create HTML for the select element in most tests
testcase_html = (options, attributes = '') ->
  options_obj = {}
  # If options is a simple array, convert to an object with equal keys and values
  if type_is_array options
    for option in options
      options_obj[option] = option
  else
    options_obj = options

  # Construct the HTML
  tmpl = "<select #{attributes}>"
  for value, label of options_obj
    q = if value.indexOf('"') > -1 then "'" else '"'
    tmpl += "<option value=#{q}#{value}#{q}>#{label}</option>"
  tmpl += "</select>"

testcase = (options, settings = {}, attributes = '') ->
  # If options is a string we're good, otherwise create the HTML
  if typeof options is 'string'
    tmpl = options
  else
    tmpl = testcase_html options, attributes
    
  # Get a "testcase" that is adapted to jquery / prototype
  obj = fw_testcase tmpl, settings
  
  # Add commonly used function to the object
  # these are just "shortcuts" making the tests a lot more readable for common
  # operations like opening the dropdown or finding out how many results are shown
  obj.open_drop               = () -> @container.trigger('mousedown')
  obj.get_val                 = () -> @select.val()
  obj.get_results             = () -> @div.find('.active-result')
  obj.get_result_groups       = () -> @div.find('.group-result')
  obj.click_result            = (n) -> @get_results()[n].trigger("mouseup")
  obj.set_search = (v) ->
    @search_field.val(v)
    @search_field.trigger('keyup')
    
  # Return the testcase
  obj