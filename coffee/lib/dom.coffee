temp_el = document.createElement 'div'

DOM =
  find_parent: (el, check) ->
    current_node = el.parentNode
    until current_node is null or check current_node
      current_node = current_node.parentNode
      # If we get beyond the <html> element, consider it not found
      current_node = null if current_node is document
    return current_node
  
  find_next_sibling: (el, check) ->
    current_sibling = el.nextSibling
    until current_sibling is null or check current_sibling
      current_sibling = current_sibling.nextSibling
    return current_sibling
  
  find_prev_sibling: (el, check) ->
    current_sibling = el.previousSibling
    until current_sibling is null or check current_sibling
      current_sibling = current_sibling.previousSibling
    return current_sibling
  
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