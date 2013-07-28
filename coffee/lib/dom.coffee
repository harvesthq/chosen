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
  DOM.add_class = (el, class_name) -> el.className += " #{class_name}" unless has_class el, class_name
  DOM.remove_class = (el, class_name) -> el.className = trim " #{el.className} ".replace(" #{class_name}", "")

if 'getComputedStyle' of window
  DOM.get_style = (el, prop) -> window.getComputedStyle(el, null).getPropertyValue(prop)
else if 'currentStyle' of temp_el
  DOM.get_style = (el, prop) -> el.currentStyle[camel_case prop]
else
  DOM.get_style = (el, prop) -> ""