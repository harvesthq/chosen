class @Chosen extends AbstractChosen

  setup: ->
    @current_selectedIndex = @form_field.selectedIndex

  set_up_html: ->
    container_classes = ["chosen-container"]
    container_classes.push "chosen-container-" + (if @is_multiple then "multi" else "single")
    container_classes.push @form_field.className if @inherit_select_classes && @form_field.className
    container_classes.push "chosen-rtl" if @is_rtl

    container_props =
      'class': container_classes.join ' '
      'title': @form_field.title

    container_props.id = @form_field.id.replace(/[^\w]/g, '_') + "_chosen" if @form_field.id.length

    @container = new Element('div', container_props)

    # CSP without 'unsafe-inline' doesn't allow setting the style attribute directly
    @container.setStyle(width: this.container_width())

    if @is_multiple
      @container.update this.get_multi_html()
    else
      @container.update this.get_single_html()

    @form_field.hide().insert({ after: @container })
    @dropdown = @container.down('div.chosen-drop')

    @search_field = @container.down('input')
    @search_results = @container.down('ul.chosen-results')
    this.search_field_scale()

    @search_no_results = @container.down('li.no-results')

    if @is_multiple
      @search_choices = @container.down('ul.chosen-choices')
      @search_container = @container.down('li.search-field')
    else
      @search_container = @container.down('div.chosen-search')
      @selected_item = @container.down('.chosen-single')

    this.results_build()
    this.set_tab_index()
    this.set_label_behavior()

  on_ready: ->
    @form_field.fire("chosen:ready", {chosen: this})

  register_observers: ->
    @container.observe "touchstart", (evt) => this.container_mousedown(evt)
    @container.observe "touchend", (evt) => this.container_mouseup(evt)

    @container.observe "mousedown", (evt) => this.container_mousedown(evt)
    @container.observe "mouseup", (evt) => this.container_mouseup(evt)
    @container.observe "mouseenter", (evt) => this.mouse_enter(evt)
    @container.observe "mouseleave", (evt) => this.mouse_leave(evt)

    @search_results.observe "mouseup", (evt) => this.search_results_mouseup(evt)
    @search_results.observe "mouseover", (evt) => this.search_results_mouseover(evt)
    @search_results.observe "mouseout", (evt) => this.search_results_mouseout(evt)
    @search_results.observe "mousewheel", (evt) => this.search_results_mousewheel(evt)
    @search_results.observe "DOMMouseScroll", (evt) => this.search_results_mousewheel(evt)

    @search_results.observe "touchstart", (evt) => this.search_results_touchstart(evt)
    @search_results.observe "touchmove", (evt) => this.search_results_touchmove(evt)
    @search_results.observe "touchend", (evt) => this.search_results_touchend(evt)

    @form_field.observe "chosen:updated", (evt) => this.results_update_field(evt)
    @form_field.observe "chosen:activate", (evt) => this.activate_field(evt)
    @form_field.observe "chosen:open", (evt) => this.container_mousedown(evt)
    @form_field.observe "chosen:close", (evt) => this.close_field(evt)

    @search_field.observe "blur", (evt) => this.input_blur(evt)
    @search_field.observe "keyup", (evt) => this.keyup_checker(evt)
    @search_field.observe "keydown", (evt) => this.keydown_checker(evt)
    @search_field.observe "focus", (evt) => this.input_focus(evt)
    @search_field.observe "cut", (evt) => this.clipboard_event_checker(evt)
    @search_field.observe "paste", (evt) => this.clipboard_event_checker(evt)

    if @is_multiple
      @search_choices.observe "click", (evt) => this.choices_click(evt)
    else
      @container.observe "click", (evt) => evt.preventDefault() # gobble click of anchor

  destroy: ->
    @container.ownerDocument.stopObserving "click", @click_test_action

    for event in ['chosen:updated', 'chosen:activate', 'chosen:open', 'chosen:close']
      @form_field.stopObserving(event)

    @container.stopObserving()
    @search_results.stopObserving()
    @search_field.stopObserving()
    @form_field_label.stopObserving() if @form_field_label?

    if @is_multiple
      @search_choices.stopObserving()
      @container.select(".search-choice-close").each (choice) ->
        choice.stopObserving()
    else
      @selected_item.stopObserving()

    if @search_field.tabIndex
      @form_field.tabIndex = @search_field.tabIndex

    @container.remove()
    @form_field.show()

  search_field_disabled: ->
    @is_disabled = @form_field.disabled || @form_field.up('fieldset')?.disabled || false

    if @is_disabled
      @container.addClassName 'chosen-disabled'
    else
      @container.removeClassName 'chosen-disabled'

    @search_field.disabled = @is_disabled

    unless @is_multiple
      @selected_item.stopObserving 'focus', this.activate_field

    if @is_disabled
      this.close_field()
    else unless @is_multiple
      @selected_item.observe 'focus', this.activate_field

  container_mousedown: (evt) ->
    return if @is_disabled

    if evt and evt.type in ['mousedown', 'touchstart'] and not @results_showing
      evt.preventDefault()

    if not (evt? and evt.target.hasClassName "search-choice-close")
      if not @active_field
        @search_field.clear() if @is_multiple
        @container.ownerDocument.observe "click", @click_test_action
        this.results_show()
      else if not @is_multiple and evt and (evt.target is @selected_item || evt.target.up("a.chosen-single"))
        this.results_toggle()

      this.activate_field()

  container_mouseup: (evt) ->
    this.results_reset(evt) if evt.target.nodeName is "ABBR" and not @is_disabled

  search_results_mousewheel: (evt) ->
    delta = evt.deltaY or -evt.wheelDelta or evt.detail
    if delta?
      evt.preventDefault()
      delta = delta * 40 if evt.type is 'DOMMouseScroll'
      @search_results.scrollTop = delta + @search_results.scrollTop

  blur_test: (evt) ->
    this.close_field() if not @active_field and @container.hasClassName("chosen-container-active")

  close_field: ->
    @container.ownerDocument.stopObserving "click", @click_test_action

    @active_field = false
    this.results_hide()

    @container.removeClassName "chosen-container-active"
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()
    @search_field.blur()

  activate_field: ->
    return if @is_disabled

    @container.addClassName "chosen-container-active"
    @active_field = true

    @search_field.value = this.get_search_field_value()
    @search_field.focus()

  test_active_click: (evt) ->
    if evt.target.up('.chosen-container') is @container
      @active_field = true
    else
      this.close_field()

  results_build: ->
    @parsing = true
    @selected_option_count = null

    @results_data = SelectParser.select_to_array @form_field

    if @is_multiple
      @search_choices.select("li.search-choice").invoke("remove")
    else if not @is_multiple
      this.single_set_selected_text()
      if @disable_search or @form_field.options.length <= @disable_search_threshold
        @search_field.readOnly = true
        @container.addClassName "chosen-container-single-nosearch"
      else
        @search_field.readOnly = false
        @container.removeClassName "chosen-container-single-nosearch"

    this.update_results_content this.results_option_build({first:true})

    this.search_field_disabled()
    this.show_search_field_default()
    this.search_field_scale()

    @parsing = false

  result_do_highlight: (el) ->
      this.result_clear_highlight()

      @result_highlight = el
      @result_highlight.addClassName "highlighted"

      maxHeight = parseInt @search_results.getStyle('maxHeight'), 10
      visible_top = @search_results.scrollTop
      visible_bottom = maxHeight + visible_top

      high_top = @result_highlight.positionedOffset().top
      high_bottom = high_top + @result_highlight.getHeight()

      if high_bottom >= visible_bottom
        @search_results.scrollTop = if (high_bottom - maxHeight) > 0 then (high_bottom - maxHeight) else 0
      else if high_top < visible_top
        @search_results.scrollTop = high_top

  result_clear_highlight: ->
    @result_highlight.removeClassName('highlighted') if @result_highlight
    @result_highlight = null

  results_show: ->
    if @is_multiple and @max_selected_options <= this.choices_count()
      @form_field.fire("chosen:maxselected", {chosen: this})
      return false

    @container.addClassName "chosen-with-drop"
    @results_showing = true

    @search_field.focus()
    @search_field.value = this.get_search_field_value()

    this.winnow_results()
    @form_field.fire("chosen:showing_dropdown", {chosen: this})

  update_results_content: (content) ->
    @search_results.update content

  results_hide: ->
    if @results_showing
      this.result_clear_highlight()

      @container.removeClassName "chosen-with-drop"
      @form_field.fire("chosen:hiding_dropdown", {chosen: this})

    @results_showing = false


  set_tab_index: (el) ->
    if @form_field.tabIndex
      ti = @form_field.tabIndex
      @form_field.tabIndex = -1
      @search_field.tabIndex = ti

  set_label_behavior: ->
    @form_field_label = @form_field.up("label") # first check for a parent label
    if not @form_field_label?
      @form_field_label = $$("label[for='#{@form_field.id}']").first() #next check for a for=#{id}

    if @form_field_label?
      @form_field_label.observe "click", this.label_click_handler

  show_search_field_default: ->
    if @is_multiple and this.choices_count() < 1 and not @active_field
      @search_field.value = @default_text
      @search_field.addClassName "default"
    else
      @search_field.value = ""
      @search_field.removeClassName "default"

  search_results_mouseup: (evt) ->
    target = if evt.target.hasClassName("active-result") then evt.target else evt.target.up(".active-result")
    if target
      @result_highlight = target
      this.result_select(evt)
      @search_field.focus()

  search_results_mouseover: (evt) ->
    target = if evt.target.hasClassName("active-result") then evt.target else evt.target.up(".active-result")
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if evt.target.hasClassName('active-result') or evt.target.up('.active-result')

  choice_build: (item) ->
    choice = new Element('li', { class: "search-choice" }).update("<span>#{this.choice_label(item)}</span>")

    if item.disabled
      choice.addClassName 'search-choice-disabled'
    else
      close_link = new Element('a', { href: '#', class: 'search-choice-close', rel: item.array_index })
      close_link.observe "click", (evt) => this.choice_destroy_link_click(evt)
      choice.insert close_link

    @search_container.insert { before: choice }

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy evt.target unless @is_disabled

  choice_destroy: (link) ->
    if this.result_deselect link.readAttribute("rel")
      if @active_field
        @search_field.focus()
      else
        this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and this.get_search_field_value().length < 1

      link.up('li').remove()

      this.search_field_scale()

  results_reset: ->
    this.reset_single_select_options()
    @form_field.options[0].selected = true
    this.single_set_selected_text()
    this.show_search_field_default()
    this.results_reset_cleanup()
    this.trigger_form_field_change()
    this.results_hide() if @active_field

  results_reset_cleanup: ->
    @current_selectedIndex = @form_field.selectedIndex
    deselect_trigger = @selected_item.down("abbr")
    deselect_trigger.remove() if(deselect_trigger)

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight
      this.result_clear_highlight()

      if @is_multiple and @max_selected_options <= this.choices_count()
        @form_field.fire("chosen:maxselected", {chosen: this})
        return false

      if @is_multiple
        high.removeClassName("active-result")
      else
        this.reset_single_select_options()

      high.addClassName("result-selected")

      item = @results_data[ high.getAttribute("data-option-array-index") ]
      item.selected = true

      @form_field.options[item.options_index].selected = true
      @selected_option_count = null
      @search_field.value = ""

      if @is_multiple
        this.choice_build item
      else
        this.single_set_selected_text(this.choice_label(item))

      if @is_multiple && (!@hide_results_on_select || (evt.metaKey or evt.ctrlKey))
        this.winnow_results()
      else
        this.results_hide()
        this.show_search_field_default()

      this.trigger_form_field_change() if @is_multiple || @form_field.selectedIndex != @current_selectedIndex
      @current_selectedIndex = @form_field.selectedIndex

      evt.preventDefault()

      this.search_field_scale()

  single_set_selected_text: (text=@default_text) ->
    if text is @default_text
      @selected_item.addClassName("chosen-default")
    else
      this.single_deselect_control_build()
      @selected_item.removeClassName("chosen-default")

    @selected_item.down("span").update(text)

  result_deselect: (pos) ->
    result_data = @results_data[pos]

    if not @form_field.options[result_data.options_index].disabled
      result_data.selected = false

      @form_field.options[result_data.options_index].selected = false
      @selected_option_count = null

      this.result_clear_highlight()
      this.winnow_results() if @results_showing

      this.trigger_form_field_change()
      this.search_field_scale()
      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
    @selected_item.down("span").insert { after: "<abbr class=\"search-choice-close\"></abbr>" } unless @selected_item.down("abbr")
    @selected_item.addClassName("chosen-single-with-deselect")

  get_search_field_value: ->
    @search_field.value

  get_search_text: ->
    this.get_search_field_value().strip()

  escape_html: (text) ->
    text.escapeHTML()

  winnow_results_set_highlight: ->
    if not @is_multiple
      do_high = @search_results.down(".result-selected.active-result")

    if not do_high?
      do_high = @search_results.down(".active-result")

    this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    @search_results.insert this.get_no_results_html(terms)
    @form_field.fire("chosen:no_results", {chosen: this})

  no_results_clear: ->
    nr = null
    nr.remove() while nr = @search_results.down(".no-results")


  keydown_arrow: ->
    if @results_showing and @result_highlight
      next_sib = @result_highlight.next('.active-result')
      this.result_do_highlight next_sib if next_sib
    else
      this.results_show()

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      sibs = @result_highlight.previousSiblings()
      actives = @search_results.select("li.active-result")
      prevs = sibs.intersect(actives)

      if prevs.length
        this.result_do_highlight prevs.first()
      else
        this.results_hide() if this.choices_count() > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.down("a")
      this.clear_backstroke()
    else
      next_available_destroy = @search_container.siblings().last()
      if next_available_destroy and next_available_destroy.hasClassName("search-choice") and not next_available_destroy.hasClassName("search-choice-disabled")
        @pending_backstroke = next_available_destroy
        @pending_backstroke.addClassName("search-choice-focus") if @pending_backstroke
        if @single_backstroke_delete
          @keydown_backstroke()
        else
          @pending_backstroke.addClassName("search-choice-focus")

  clear_backstroke: ->
    @pending_backstroke.removeClassName("search-choice-focus") if @pending_backstroke
    @pending_backstroke = null

  search_field_scale: ->
    return unless @is_multiple

    style_block =
      position: 'absolute'
      left: '-1000px'
      top: '-1000px'
      display: 'none'
      whiteSpace: 'pre'

    styles = ['fontSize', 'fontStyle', 'fontWeight', 'fontFamily', 'lineHeight', 'textTransform', 'letterSpacing']

    for style in styles
      style_block[style] = @search_field.getStyle(style)

    div = new Element('div').update(this.escape_html(this.get_search_field_value()))
    # CSP without 'unsafe-inline' doesn't allow setting the style attribute directly
    div.setStyle(style_block)
    document.body.appendChild(div)

    width = div.measure('width') + 25
    div.remove()

    if container_width = @container.getWidth()
      width = Math.min(container_width - 10, width)

    @search_field.setStyle(width: width + 'px')

  trigger_form_field_change:  ->
    triggerHtmlEvent @form_field, 'input'
    triggerHtmlEvent @form_field, 'change'

  triggerHtmlEvent = (element, eventType) ->
    if element.dispatchEvent  # Modern way:
      try
        evt = new Event(eventType, bubbles: true, cancelable: true)
      catch
        evt = document.createEvent('HTMLEvents')
        evt.initEvent(eventType, true, true);
      element.dispatchEvent(evt)
    else # Old IE:
      element.fireEvent("on#{eventType}", document.createEventObject());
