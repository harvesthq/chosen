$ = jQuery

$.fn.extend({
  chosen: (options) ->
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    # Continue on if running IE document type but in compatibility mode
    return this unless AbstractChosen.browser_is_supported()
    this.each (input_field) ->
      $this = $ this
      chosen = $this.data('chosen')
      if options is 'destroy'
        if chosen instanceof Chosen
          chosen.destroy()
        return
      unless chosen instanceof Chosen
        $this.data('chosen', new Chosen(this, options))

      return

})

class Chosen extends AbstractChosen

  setup: ->
    @form_field_jq = $ @form_field
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

    @container = ($ "<div />", container_props)

    # CSP without 'unsafe-inline' doesn't allow setting the style attribute directly
    @container.width this.container_width()

    if @is_multiple
      @container.html this.get_multi_html()
    else
      @container.html this.get_single_html()

    @form_field_jq.hide().after @container
    @dropdown = @container.find('div.chosen-drop').first()

    @search_field = @container.find('input').first()
    @search_results = @container.find('ul.chosen-results').first()
    this.search_field_scale()

    @search_no_results = @container.find('li.no-results').first()

    if @is_multiple
      @search_choices = @container.find('ul.chosen-choices').first()
      @search_container = @container.find('li.search-field').first()
    else
      @search_container = @container.find('div.chosen-search').first()
      @selected_item = @container.find('.chosen-single').first()

    this.results_build()
    this.set_tab_index()
    this.set_label_behavior()

  on_ready: ->
    @form_field_jq.trigger("chosen:ready", {chosen: this})

  register_observers: ->
    @container.on 'touchstart.chosen', (evt) => this.container_mousedown(evt); return
    @container.on 'touchend.chosen', (evt) => this.container_mouseup(evt); return

    @container.on 'mousedown.chosen', (evt) => this.container_mousedown(evt); return
    @container.on 'mouseup.chosen', (evt) => this.container_mouseup(evt); return
    @container.on 'mouseenter.chosen', (evt) => this.mouse_enter(evt); return
    @container.on 'mouseleave.chosen', (evt) => this.mouse_leave(evt); return

    @search_results.on 'mouseup.chosen', (evt) => this.search_results_mouseup(evt); return
    @search_results.on 'mouseover.chosen', (evt) => this.search_results_mouseover(evt); return
    @search_results.on 'mouseout.chosen', (evt) => this.search_results_mouseout(evt); return
    @search_results.on 'mousewheel.chosen DOMMouseScroll.chosen', (evt) => this.search_results_mousewheel(evt); return

    @search_results.on 'touchstart.chosen', (evt) => this.search_results_touchstart(evt); return
    @search_results.on 'touchmove.chosen', (evt) => this.search_results_touchmove(evt); return
    @search_results.on 'touchend.chosen', (evt) => this.search_results_touchend(evt); return

    @form_field_jq.on "chosen:updated.chosen", (evt) => this.results_update_field(evt); return
    @form_field_jq.on "chosen:activate.chosen", (evt) => this.activate_field(evt); return
    @form_field_jq.on "chosen:open.chosen", (evt) => this.container_mousedown(evt); return
    @form_field_jq.on "chosen:close.chosen", (evt) => this.close_field(evt); return

    @search_field.on 'blur.chosen', (evt) => this.input_blur(evt); return
    @search_field.on 'keyup.chosen', (evt) => this.keyup_checker(evt); return
    @search_field.on 'keydown.chosen', (evt) => this.keydown_checker(evt); return
    @search_field.on 'focus.chosen', (evt) => this.input_focus(evt); return
    @search_field.on 'cut.chosen', (evt) => this.clipboard_event_checker(evt); return
    @search_field.on 'paste.chosen', (evt) => this.clipboard_event_checker(evt); return

    if @is_multiple
      @search_choices.on 'click.chosen', (evt) => this.choices_click(evt); return
    else
      @container.on 'click.chosen', (evt) -> evt.preventDefault(); return # gobble click of anchor

  destroy: ->
    $(@container[0].ownerDocument).off 'click.chosen', @click_test_action
    @form_field_label.off 'click.chosen' if @form_field_label.length > 0

    if @search_field[0].tabIndex
      @form_field_jq[0].tabIndex = @search_field[0].tabIndex

    @container.remove()
    @form_field_jq.removeData('chosen')
    @form_field_jq.show()

  search_field_disabled: ->
    @is_disabled = @form_field.disabled || @form_field_jq.parents('fieldset').is(':disabled')

    @container.toggleClass 'chosen-disabled', @is_disabled
    @search_field[0].disabled = @is_disabled

    unless @is_multiple
      @selected_item.off 'focus.chosen', this.activate_field

    if @is_disabled
      this.close_field()
    else unless @is_multiple
      @selected_item.on 'focus.chosen', this.activate_field

  container_mousedown: (evt) ->
    return if @is_disabled

    if evt and evt.type in ['mousedown', 'touchstart'] and not @results_showing
      evt.preventDefault()

    if not (evt? and ($ evt.target).hasClass "search-choice-close")
      if not @active_field
        @search_field.val "" if @is_multiple
        $(@container[0].ownerDocument).on 'click.chosen', @click_test_action
        this.results_show()
      else if not @is_multiple and evt and (($(evt.target)[0] == @selected_item[0]) || $(evt.target).parents("a.chosen-single").length)
        evt.preventDefault()
        this.results_toggle()

      this.activate_field()

  container_mouseup: (evt) ->
    this.results_reset(evt) if evt.target.nodeName is "ABBR" and not @is_disabled

  search_results_mousewheel: (evt) ->
    delta = evt.originalEvent.deltaY or -evt.originalEvent.wheelDelta or evt.originalEvent.detail if evt.originalEvent
    if delta?
      evt.preventDefault()
      delta = delta * 40 if evt.type is 'DOMMouseScroll'
      @search_results.scrollTop(delta + @search_results.scrollTop())

  blur_test: (evt) ->
    this.close_field() if not @active_field and @container.hasClass "chosen-container-active"

  close_field: ->
    $(@container[0].ownerDocument).off "click.chosen", @click_test_action

    @active_field = false
    this.results_hide()

    @container.removeClass "chosen-container-active"
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()
    @search_field.blur()

  activate_field: ->
    return if @is_disabled

    @container.addClass "chosen-container-active"
    @active_field = true

    @search_field.val(@search_field.val())
    @search_field.focus()


  test_active_click: (evt) ->
    active_container = $(evt.target).closest('.chosen-container')
    if active_container.length and @container[0] == active_container[0]
      @active_field = true
    else
      this.close_field()

  results_build: ->
    @parsing = true
    @selected_option_count = null

    @results_data = SelectParser.select_to_array @form_field

    if @is_multiple
      @search_choices.find("li.search-choice").remove()
    else
      this.single_set_selected_text()
      if @disable_search or @form_field.options.length <= @disable_search_threshold
        @search_field[0].readOnly = true
        @container.addClass "chosen-container-single-nosearch"
      else
        @search_field[0].readOnly = false
        @container.removeClass "chosen-container-single-nosearch"

    this.update_results_content this.results_option_build({first:true})

    this.search_field_disabled()
    this.show_search_field_default()
    this.search_field_scale()

    @parsing = false

  result_do_highlight: (el) ->
    if el.length
      this.result_clear_highlight()

      @result_highlight = el
      @result_highlight.addClass "highlighted"

      maxHeight = parseInt @search_results.css("maxHeight"), 10
      visible_top = @search_results.scrollTop()
      visible_bottom = maxHeight + visible_top

      high_top = @result_highlight.position().top + @search_results.scrollTop()
      high_bottom = high_top + @result_highlight.outerHeight()

      if high_bottom >= visible_bottom
        @search_results.scrollTop if (high_bottom - maxHeight) > 0 then (high_bottom - maxHeight) else 0
      else if high_top < visible_top
        @search_results.scrollTop high_top

  result_clear_highlight: ->
    @result_highlight.removeClass "highlighted" if @result_highlight
    @result_highlight = null

  results_show: ->
    if @is_multiple and @max_selected_options <= this.choices_count()
      @form_field_jq.trigger("chosen:maxselected", {chosen: this})
      return false

    unless @is_multiple
      @search_container.append @search_field

    @container.addClass "chosen-with-drop"
    @results_showing = true

    @search_field.focus()
    @search_field.val this.get_search_field_value()

    this.winnow_results()
    @form_field_jq.trigger("chosen:showing_dropdown", {chosen: this})

  update_results_content: (content) ->
    @search_results.html content

  results_hide: ->
    if @results_showing
      this.result_clear_highlight()

      unless @is_multiple
        @selected_item.prepend @search_field
        @search_field.focus()

      @container.removeClass "chosen-with-drop"
      @form_field_jq.trigger("chosen:hiding_dropdown", {chosen: this})

    @results_showing = false


  set_tab_index: (el) ->
    if @form_field.tabIndex
      ti = @form_field.tabIndex
      @form_field.tabIndex = -1
      @search_field[0].tabIndex = ti

  set_label_behavior: ->
    @form_field_label = @form_field_jq.parents("label") # first check for a parent label
    if not @form_field_label.length and @form_field.id.length
      @form_field_label = $("label[for='#{@form_field.id}']") #next check for a for=#{id}

    if @form_field_label.length > 0
      @form_field_label.on 'click.chosen', this.label_click_handler

  show_search_field_default: ->
    if @is_multiple and this.choices_count() < 1 and not @active_field
      @search_field.val(@default_text)
      @search_field.addClass "default"
    else
      @search_field.val("")
      @search_field.removeClass "default"

  search_results_mouseup: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").first()
    if target.length
      @result_highlight = target
      this.result_select(evt)
      @search_field.focus()

  search_results_mouseover: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").first()
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if $(evt.target).hasClass("active-result") or $(evt.target).parents('.active-result').first()

  choice_build: (item) ->
    choice = $('<li />', { class: "search-choice" }).html("<span>#{this.choice_label(item)}</span>")

    if item.disabled
      choice.addClass 'search-choice-disabled'
    else
      close_link = $('<a />', { class: 'search-choice-close', 'data-option-array-index': item.array_index })
      close_link.on 'click.chosen', (evt) => this.choice_destroy_link_click(evt)
      choice.append close_link

    @search_container.before  choice

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy $(evt.target) unless @is_disabled

  choice_destroy: (link) ->
    if this.result_deselect( link[0].getAttribute("data-option-array-index") )
      if @active_field
        @search_field.focus()
      else
        this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and this.get_search_field_value().length < 1

      link.parents('li').first().remove()

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
    @selected_item.find("abbr").remove()

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight

      this.result_clear_highlight()

      if @is_multiple and @max_selected_options <= this.choices_count()
        @form_field_jq.trigger("chosen:maxselected", {chosen: this})
        return false

      if @is_multiple
        high.removeClass("active-result")
      else
        this.reset_single_select_options()

      high.addClass("result-selected")

      item = @results_data[ high[0].getAttribute("data-option-array-index") ]
      item.selected = true

      @form_field.options[item.options_index].selected = true
      @selected_option_count = null
      @search_field.val("")

      if @is_multiple
        this.choice_build item
      else
        this.single_set_selected_text(this.choice_label(item))

      if @is_multiple && (!@hide_results_on_select || (evt.metaKey or evt.ctrlKey))
        this.winnow_results()
      else
        this.results_hide()
        this.show_search_field_default()

      this.trigger_form_field_change selected: @form_field.options[item.options_index].value  if @is_multiple || @form_field.selectedIndex != @current_selectedIndex
      @current_selectedIndex = @form_field.selectedIndex

      evt.preventDefault()

      this.search_field_scale()

  single_set_selected_text: (text=@default_text) ->
    if text is @default_text
      @selected_item.addClass("chosen-default")
    else
      this.single_deselect_control_build()
      @selected_item.removeClass("chosen-default")

    @selected_item.find("span").html(text)

  result_deselect: (pos) ->
    result_data = @results_data[pos]

    if not @form_field.options[result_data.options_index].disabled
      result_data.selected = false

      @form_field.options[result_data.options_index].selected = false
      @selected_option_count = null

      this.result_clear_highlight()
      this.winnow_results() if @results_showing

      this.trigger_form_field_change deselected: @form_field.options[result_data.options_index].value
      this.search_field_scale()

      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
    @selected_item.find("span").first().after "<abbr class=\"search-choice-close\"></abbr>" unless @selected_item.find("abbr").length
    @selected_item.addClass("chosen-single-with-deselect")

  get_search_field_value: ->
    @search_field.val()

  get_search_text: ->
    $.trim this.get_search_field_value()

  escape_html: (text) ->
    $('<div/>').text(text).html()

  winnow_results_set_highlight: ->
    selected_results = if not @is_multiple then @search_results.find(".result-selected.active-result") else []
    do_high = if selected_results.length then selected_results.first() else @search_results.find(".active-result").first()

    this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    no_results_html = this.get_no_results_html(terms)
    @search_results.append no_results_html
    @form_field_jq.trigger("chosen:no_results", {chosen:this})

  no_results_clear: ->
    @search_results.find(".no-results").remove()

  keydown_arrow: ->
    if @results_showing and @result_highlight
      next_sib = @result_highlight.nextAll("li.active-result").first()
      this.result_do_highlight next_sib if next_sib
    else
      this.results_show()

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      prev_sibs = @result_highlight.prevAll("li.active-result")

      if prev_sibs.length
        this.result_do_highlight prev_sibs.first()
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
      style_block[style] = @search_field.css(style)

    div = $('<div />').css(style_block)
    div.text this.get_search_field_value()
    $('body').append div

    width = div.width() + 25
    div.remove()

    if @container.is(':visible')
      width = Math.min(@container.outerWidth() - 10, width)

    @search_field.width(width)

  trigger_form_field_change: (extra) ->
    @form_field_jq.trigger "input", extra
    @form_field_jq.trigger "change", extra
