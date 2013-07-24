# DOM utility methods
temp_el = document.createElement 'div'

# Check for native String.trim
if String::trim?
  trim = (string) -> string.trim()
else
  trim = (string) -> string.replace /^\s+|\s+$/g, ''

# Check for support of ClassList
if 'classList' of temp_el
	has_class = (el, class_name) -> el.classList.contains class_name
	add_class = (el, class_name) -> el.classList.add class_name
	remove_class = (el, class_name) -> el.classList.remove class_name
else
	has_class = (el, class_name) -> " #{el.className.toUpperCase()} ".indexOf(" #{class_name.toUpperCase()} ") > -1
	add_class = (el, class_name) -> el.className += " #{class_name}" unless has_class el, class_name
	remove_class = (el, class_name) -> el.className = trim " #{el.className} ".replace(" #{class_name} ", "")

# W3C event model
if document.addEventListener?
  add_event = (el, type, fn) -> 
    # TODO: Support these emulated events in remove_event (need to store wrapper function to access it later)
    emulated_event = emulated_events[type]
    if emulated_event
      fn = emulated_event.handler(el, fn)
      type = emulated_event.mapped_to
      
    el.addEventListener(type, fn, false)
  remove_event = (el, type, fn) -> el.removeEventListener(type, fn, false)
# Legacy IE event model
else if document.attachEvent?
  # TODO: Test in Internet Explorer
  # TODO: Normalize required event properties (evt.target vs evt.srcElement, etc.)
  # TODO: mouseenter/mouseleave emulation
  add_event = (el, type, fn) -> el.attachEvent(type, fn)
  remove_event = (el, type, fn) -> el.detachEvent(type, fn)
  
# mouseenter/mouseleave emulation for unsupported browsers
# Based off technique at http://blog.stchur.com/2007/03/15/mouseenter-and-mouseleave-events-for-firefox-and-other-non-ie-browsers/
emulated_events =
  mouseenter: 
    mapped_to: 'mouseover'
    handler: (original_el, fn) ->
      (evt) ->
        # Don't fire if it's a child element (so it's not fired over and over again)
        return if original_el is evt.relatedTarget or find_parent? evt.relatedTarget, (el) -> el is original_el
          
        fn.call(this, evt)

emulated_events.mouseleave = 
  mapped_to: 'mouseout',
  handler: emulated_events.mouseenter.handler

fire_event = do ->
	# TODO: The createEvent method is deprecated. Use event constructors instead. - https://developer.mozilla.org/en-US/docs/Web/API/document.createEvent
  # W3C event model
	if document.createEvent?
    (el, type, memo = {}) ->
      event = document.createEvent "HTMLEvents"
      event.initEvent type, true, true
      event.eventName = type
      event.memo = memo
      el.dispatchEvent event
  # Legacy IE event model
  else if document.createEventObject?
    (el, type, memo = {}) ->
      event = document.createEventObject()
      event.eventType = type
      event.eventName = type
      event.memo = memo
      el.fireEvent "on#{type}", event
      
find_parent = (el, check) ->
  current_node = el.parentNode
  until current_node is null or check current_node
    current_node = current_node.parentNode
    # If we get beyond the <html> element, consider it not found
    current_node = null if current_node is document
  return current_node
  
find_next_sibling = (el, check) ->
  current_sibling = el.nextSibling
  until current_sibling is null or check current_sibling
    current_sibling = current_sibling.nextSibling
  return current_sibling

find_prev_sibling = (el, check) ->
  current_sibling = el.previousSibling
  until current_sibling is null or check current_sibling
    current_sibling = current_sibling.previousSibling
  return current_sibling

class @Chosen extends AbstractChosen

  setup: ->
    @current_selectedIndex = @form_field.selectedIndex
    @is_rtl = has_class @form_field, "chzn-rtl"

  finish_setup: ->
    add_class @form_field, "chzn-done"

  set_up_html: ->
    container_classes = ["chzn-container"]
    container_classes.push "chzn-container-" + (if @is_multiple then "multi" else "single")
    container_classes.push @form_field.className if @inherit_select_classes && @form_field.className
    container_classes.push "chzn-rtl" if @is_rtl

    container_props =
      'class': container_classes.join ' '
      'style': "width: #{this.container_width()};"
      'title': @form_field.title

    container_props.id = @form_field.id.replace(/[^\w]/g, '_') + "_chzn" if @form_field.id.length

    @container = document.createElement 'div'
    for key, value of container_props
    	@container.setAttribute key, value

    if @is_multiple
      @container.innerHTML = '<ul class="chzn-choices"><li class="search-field"><input type="text" value="' + @default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chzn-drop"><ul class="chzn-results"></ul></div>'
    else
      @container.innerHTML = '<a href="javascript:void(0)" class="chzn-single chzn-default" tabindex="-1"><span>' + @default_text + '</span><div><b></b></div></a><div class="chzn-drop"><div class="chzn-search"><input type="text" autocomplete="off" /></div><ul class="chzn-results"></ul></div>'

    @form_field.style.display = 'none'
    @form_field.parentNode.appendChild @container    
    
    @dropdown = @container.querySelector('div.chzn-drop')

    @search_field = @container.getElementsByTagName('input')[0]
    @search_results = @container.querySelector('ul.chzn-results')
    this.search_field_scale()

    @search_no_results = @container.querySelector('li.no-results')

    if @is_multiple
      @search_choices = @container.querySelector('ul.chzn-choices')
      @search_container = @container.querySelector('li.search-field')
    else
      @search_container = @container.querySelector('div.chzn-search')
      @selected_item = @container.querySelector('.chzn-single')
    
    this.results_build()
    this.set_tab_index()
    this.set_label_behavior()
    fire_event @form_field, "liszt:ready", {chosen: this}

  register_observers: ->
    add_event @container, 'mousedown', (evt) => this.container_mousedown(evt); return
    add_event @container, 'mouseup', (evt) => this.container_mouseup(evt); return
    add_event @container, 'mouseenter', (evt) => this.mouse_enter(evt); return
    add_event @container, 'mouseleave', (evt) => this.mouse_leave(evt); return

    add_event @search_results, "mouseup", (evt) => this.search_results_mouseup(evt); return
    add_event @search_results, "mouseover", (evt) => this.search_results_mouseover(evt); return
    add_event @search_results, "mouseout", (evt) => this.search_results_mouseout(evt); return
    add_event @search_results, 'mousewheel DOMMouseScroll', (evt) => this.search_results_mousewheel(evt); return

    add_event @form_field, "liszt:updated", (evt) => this.results_update_field(evt); return
    add_event @form_field, "liszt:activate", (evt) => this.activate_field(evt); return
    add_event @form_field, "liszt:open", (evt) => this.container_mousedown(evt); return

    add_event @search_field, "blur",  (evt) => this.input_blur(evt); return
    add_event @search_field, "keyup",  (evt) => this.keyup_checker(evt); return
    add_event @search_field, "keydown", (evt) => this.keydown_checker(evt); return
    add_event @search_field, "focus", (evt) => this.input_focus(evt); return

    if @is_multiple
      add_event @search_choices, "click",  (evt) => this.choices_click(evt); return
    else
      add_event @container, "click", (evt) => evt.preventDefault(); return # gobble click of anchor

  search_field_disabled: ->
    @is_disabled = @form_field.disabled
    if(@is_disabled)
      add_class @container, 'chzn-disabled'
      @search_field.disabled = true
      remove_event @selected_item, "focus", @activate_action if !@is_multiple
      this.close_field()
    else
      remove_class @container, 'chzn-disabled'
      @search_field.disabled = false
      add_event @selected_item, "focus", @activate_action if !@is_multiple

  container_mousedown: (evt) ->
    if !@is_disabled
      if evt and evt.type is "mousedown" and not @results_showing
        evt.preventDefault()

      if not (evt? and has_class evt.target, "search-choice-close")
        if not @active_field
          @search_field.value = "" if @is_multiple
          add_event document, "click", @click_test_action
          this.results_show()
        else if not @is_multiple and evt and ((evt.target == @selected_item) || find_parent(evt.target, (el) -> has_class el, ".chzn-single")?)
          evt.preventDefault()
          this.results_toggle()

        this.activate_field()

  container_mouseup: (evt) ->
    this.results_reset(evt) if evt.target.nodeName is "ABBR" and not @is_disabled

  search_results_mousewheel: (evt) ->
    delta = -evt.originalEvent?.wheelDelta or evt.originialEvent?.detail
    if delta?
      evt.preventDefault()
      delta = delta * 40 if evt.type is 'DOMMouseScroll'
      @search_results.scrollTop(delta + @search_results.scrollTop())

  blur_test: (evt) ->
    this.close_field() if not @active_field and has_class @container, "chzn-container-active"

  close_field: ->
    remove_event document, "click", @click_test_action

    @active_field = false
    this.results_hide()

    remove_class @container, "chzn-container-active"
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
    add_class @container, "chzn-container-active"
    @active_field = true

    # What is this even doing? It was present in the jQuery version so has been retained here.
    @search_field.value = @search_field.value
    @search_field.focus()


  test_active_click: (evt) ->
    selected_container = find_parent evt.target.parentNode, (el) -> has_class el, 'chzn-container'
    
    if @container is selected_container
      @active_field = true
    else
      this.close_field()

  results_build: ->
    @parsing = true
    @selected_option_count = null

    @results_data = SelectParser.select_to_array @form_field

    if @is_multiple
      for el in @search_choices.querySelectorAll("li.search-choice")
      	el.parentNode.removeChild el
    else if not @is_multiple
      this.single_set_selected_text()
      if @disable_search or @form_field.options.length <= @disable_search_threshold
        @search_field.readOnly = true
        add_class @container, "chzn-container-single-nosearch"
      else
        @search_field.readOnly = false
        remove_class @container, "chzn-container-single-nosearch"

    this.update_results_content this.results_option_build({first:true})

    this.search_field_disabled()
    this.show_search_field_default()
    this.search_field_scale()

    @parsing = false

  result_do_highlight: (el) ->
    if el?
      this.result_clear_highlight()

      @result_highlight = el
      add_class @result_highlight, "highlighted"

      maxHeight = parseInt window.getComputedStyle(@search_results, null).getPropertyValue('max-height'), 10
      visible_top = @search_results.scrollTop
      visible_bottom = maxHeight + visible_top

      high_top = @result_highlight.offsetTop
      high_bottom = high_top + @result_highlight.clientHeight

      if high_bottom >= visible_bottom
        @search_results.scrollTop = if (high_bottom - maxHeight) > 0 then (high_bottom - maxHeight) else 0
      else if high_top < visible_top
        @search_results.scrollTop = high_top

  result_clear_highlight: ->
    remove_class @result_highlight, "highlighted" if @result_highlight
    @result_highlight = null

  results_show: ->
    if @is_multiple and @max_selected_options <= this.choices_count()
      fire_event @form_field, "liszt:maxselected", {chosen: this}
      return false

    add_class @container, "chzn-with-drop"
    fire_event @form_field, "liszt:showing_dropdown", {chosen: this}

    @results_showing = true

    @search_field.focus()
    @search_field.value = @search_field.value

    this.winnow_results()

  update_results_content: (content) ->
    @search_results.innerHTML = content

  results_hide: ->
    if @results_showing
      this.result_clear_highlight()

      remove_class @container, "chzn-with-drop"
      fire_event @form_field, "liszt:hiding_dropdown", {chosen: this}

    @results_showing = false


  set_tab_index: (el) ->
    if @form_field.tabindex
      ti = @form_field.tabindex
      @form_field.tabindex = -1
      @search_field.tabindex = ti

  set_label_behavior: ->
    @form_field_label = find_parent @form_field, (el) -> el.nodeName.toUpperCase = 'LABEL' # first check for a parent label
    
    if not @form_field_label? and @form_field.id.length
      @form_field_label = document.querySelector("label[for='#{@form_field.id}']") #next check for a for=#{id}

    if @form_field_label?
      @form_field_label.click (evt) => if @is_multiple then this.container_mousedown(evt) else this.activate_field()

  show_search_field_default: ->
    if @is_multiple and this.choices_count() < 1 and not @active_field
      @search_field.value = @default_text
      add_class @search_field, "default"
    else
      @search_field.value = ""
      remove_class @search_field, "default"

  search_results_mouseup: (evt) ->
    target = if has_class evt.target, "active-result" then evt.target else find_parent evt.target, (el) -> has_class el, "active-result"
    if target?
      @result_highlight = target
      this.result_select(evt)
      @search_field.focus()

  search_results_mouseover: (evt) ->
    target = if has_class evt.target, "active-result" then evt.target else find_parent evt.target, (el) -> has_class el, "active-result"
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if has_class evt.target, "active-result" or find_parent evt.target, (el) -> has_class el, "active-result"

  choice_build: (item) ->
    choice = document.createElement 'li'
    choice.className = "search-choice"
    choice.innerHTML = "<span>#{item.html}</span>"

    if item.disabled
      add_class choice, 'search-choice-disabled'
    else
      close_link = document.createElement 'a' 
      close_link.href = '#'
      close_link.className = 'search-choice-close'
      close_link.rel = item.array_index
      add_event close_link, 'click', (evt) => this.choice_destroy_link_click(evt)
      choice.appendChild close_link
    
    @search_container.parentNode.insertBefore choice, @search_container

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy evt.target unless @is_disabled

  choice_destroy: (link) ->
    if this.result_deselect (link.getAttribute "rel")
      this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and @search_field.value.length < 1

      li = find_parent link, (el) -> el.nodeName.toUpperCase() is 'LI'
      li.parentNode.removeChild(li) if li?

      this.search_field_scale()

  results_reset: ->
    @form_field.options[0].selected = true
    @selected_option_count = null
    this.single_set_selected_text()
    this.show_search_field_default()
    this.results_reset_cleanup()
    fire_event @form_field, "change"
    this.results_hide() if @active_field

  results_reset_cleanup: ->
    @current_selectedIndex = @form_field.selectedIndex
    @selected_item.getElementsByTagName("abbr")[0].remove()

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight

      this.result_clear_highlight()

      if @is_multiple and @max_selected_options <= this.choices_count()
        fire_event @form_field, "liszt:maxselected", {chosen: this}
        return false

      if @is_multiple
        remove_class high, "active-result"
      else
        remove_class el, "result-selected" for el in @search_results.querySelectorAll(".result-selected")
        @result_single_selected = high

      add_class high, "result-selected"

      item = @results_data[ high.getAttribute("data-option-array-index") ]
      item.selected = true

      @form_field.options[item.options_index].selected = true
      @selected_option_count = null

      if @is_multiple
        this.choice_build item
      else
        this.single_set_selected_text(item.text)

      this.results_hide() unless (evt.metaKey or evt.ctrlKey) and @is_multiple

      @search_field.value = ""

      fire_event @form_field, "change", {'selected': @form_field.options[item.options_index].value} if @is_multiple || @form_field.selectedIndex != @current_selectedIndex
      @current_selectedIndex = @form_field.selectedIndex
      this.search_field_scale()

  single_set_selected_text: (text=@default_text) ->
    if text is @default_text
      add_class @selected_item, "chzn-default"
    else
      this.single_deselect_control_build()
      remove_class @selected_item, "chzn-default"

    @selected_item.getElementsByTagName("span")[0].textContent = text

  result_deselect: (pos) ->
    result_data = @results_data[pos]

    if not @form_field.options[result_data.options_index].disabled
      result_data.selected = false

      @form_field.options[result_data.options_index].selected = false
      @selected_option_count = null

      this.result_clear_highlight()
      this.winnow_results() if @results_showing

      fire_event @form_field, "change", {deselected: @form_field.options[result_data.options_index].value}
      this.search_field_scale()

      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
		
    if @selected_item.getElementsByTagName("abbr").length is 0
      span = @selected_item.getElementsByTagName('span')[0]
      abbr = document.createElement('abbr')
      abbr.className = "search-choice-close"
      span.parentNode.insertBefore abbr, span.nextSibling

    add_class @selected_item, "chzn-single-with-deselect"

  get_search_text: ->
    if @search_field.value is @default_text 
      ""
    else
      temp_el = document.createElement "div"
      temp_el.textContent = @search_field.value.trim()
      return temp_el.innerHTML

  winnow_results_set_highlight: ->
    selected_results = if not @is_multiple then @search_results.querySelectorAll(".result-selected.active-result") else []
    do_high = if selected_results.length then selected_results[0] else @search_results.querySelector(".active-result")

    this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    li = document.createElement 'li'
    li.className = 'no-results'
    li.innerHTML = @results_none_found + ' '
    
    span = document.createElement 'span'
    span.textContent = terms
    li.appendChild span
    
    @search_results.appendChild li

  no_results_clear: ->
    no_results = @search_results.querySelector(".no-results")
    no_results.parentNode.removeChild no_results if no_results?

  keydown_arrow: ->
    if @results_showing and @result_highlight
      next_sib = find_next_sibling @result_highlight, (el) => el.nodeName.toUpperCase() == "LI" and has_class el, "active-result"
      this.result_do_highlight next_sib if next_sib
    else
      this.results_show()

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      prev_sib = find_prev_sibling @result_highlight, (el) => el.nodeName.toUpperCase() == "LI" and has_class el, "active-result"

      if prev_sib?
        this.result_do_highlight prev_sib
      else
        this.results_hide() if this.choices_count() > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.find("a").first()
      this.clear_backstroke()
    else
      next_available_destroy = @search_container.siblings("li.search-choice").last()
      if next_available_destroy.length and not next_available_destroy.hasClass("search-choice-disabled")
        @pending_backstroke = next_available_destroy
        if @single_backstroke_delete
          @keydown_backstroke()
        else
          @pending_backstroke.addClass "search-choice-focus"

  clear_backstroke: ->
    @pending_backstroke.removeClass "search-choice-focus" if @pending_backstroke
    @pending_backstroke = null

  keydown_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()

    this.clear_backstroke() if stroke != 8 and this.pending_backstroke

    switch stroke
      when 8
        @backstroke_length = this.search_field.value.length
        break
      when 9
        this.result_select(evt) if this.results_showing and not @is_multiple
        @mouse_on_container = false
        break
      when 13
        evt.preventDefault()
        break
      when 38
        evt.preventDefault()
        this.keyup_arrow()
        break
      when 40
        evt.preventDefault()
        this.keydown_arrow()
        break

  search_field_scale: ->
    if @is_multiple
      h = 0
      w = 0

      style_block = "position:absolute; left: -1000px; top: -1000px; display:none;"
      styles = ['font-size','font-style', 'font-weight', 'font-family','line-height', 'text-transform', 'letter-spacing']

      for style in styles
        style_block += style + ":" + @search_field.style[style] + ";"

      div = document.createElement 'div'
      div.style = style_block
      div.textContent = @search_field.value
      document.body.appendChild div

      w = div.offsetWidth + 25
      div.parentNode.removeChild div

      f_width = @container.outerWidth

      if( w > f_width - 10 )
        w = f_width - 10

      @search_field.style.width = w + 'px'
