temp_el = document.createElement 'div'

DOM =
  find_parent: (el, check) ->
    result = DOM.find_traversal el, 'parentNode', (el) -> el is document or check(el)
    # If we get beyond the <html> element, consider it not found
    (if result is document then null else result)

  find_next_sibling: (el, check) ->
    DOM.find_traversal el, 'nextSibling', check

  find_prev_sibling: (el, check) ->
    DOM.find_traversal el, 'previousSibling', check
    
  find_traversal: (el, property, check) ->
    current = el[property]
    until current is null or check current
      current = current[property]
    return current
  
# Check for support of ClassList
if 'classList' of temp_el
  DOM.has_class = (el, class_name) -> el.classList.contains class_name
  DOM.add_class = (el, class_name) -> el.classList.add class_name
  DOM.remove_class = (el, class_name) -> el.classList.remove class_name
else
  DOM.has_class = (el, class_name) -> " #{el.className.toUpperCase()} ".indexOf(" #{class_name.toUpperCase()} ") > -1
  DOM.add_class = (el, class_name) -> el.className += " #{class_name}" unless DOM.has_class el, class_name
  DOM.remove_class = (el, class_name) -> el.className = Util.trim " #{el.className} ".replace(" #{class_name}", "")

if 'getComputedStyle' of window
  DOM.get_style = (el, prop) -> window.getComputedStyle(el, null).getPropertyValue(prop)
else if 'currentStyle' of temp_el
  DOM.get_style = (el, prop) -> el.currentStyle[Util.camel_case prop]
else
  DOM.get_style = (el, prop) -> ""
    
# Function to get a unique ID for the specified element
if 'uniqueID' of temp_el
  # IE has a unique ID built-in; let's just use that
  DOM.unique_id = (el) -> el.uniqueID
else
  DOM.unique_id = (el) ->
    # Check if an ID was already generated
    if (id = el.getAttribute('chzn-js-id'))?
      return parseInt id, 10
      # No ID, so need to generate one
    else
      id = DOM.unique_id.max++
      el.setAttribute('chzn-js-id', id)
      return id

  DOM.unique_id.max = 0
    
temp_el = null