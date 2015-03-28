$ = jQuery

$.fn.extend({
  chosen: (options) ->
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    # Continue on if running IE document type but in compatibility mode
    return this unless AbstractChosen.browser_is_supported()
    this.each (input_field) ->
      $this = $ this
      chosen = $this.data('chosen')
      if options is 'destroy' && chosen instanceof Chosen
        chosen.destroy()
      else unless chosen instanceof Chosen
        $this.data('chosen', new Chosen(this, options))

      return

})

class Chosen extends AbstractChosen

  setup: ->
    @form_field_jq = $ @form_field
    @current_selectedIndex = @form_field.selectedIndex
    @is_rtl = @form_field_jq.hasClass "chosen-rtl"

  set_up_html: ->
    container_classes = ["chosen-container"]
    container_classes.push "chosen-container-" + (if @is_multiple then "multi" else "single")
    container_classes.push @form_field.className if @inherit_select_classes && @form_field.className
    container_classes.push "chosen-rtl" if @is_rtl

    container_props =
      'class': container_classes.join ' '
      'style': "width: #{this.container_width()};"
      'title': @form_field.title

    container_props.id = @form_field.id.replace(/[^\w]/g, '_') + "_chosen" if @form_field.id.length

    @container = ($ "<div />", container_props)

    if @is_multiple
      @container.html '<ul class="chosen-choices"><li class="search-field"><input type="text" value="' + @default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chosen-drop"><ul class="chosen-results"></ul></div>'
    else
      @container.html '<a class="chosen-single chosen-default"><span>' + @default_text + '</span><div><b></b></div></a><div class="chosen-drop"><div class="chosen-search"><input type="text" autocomplete="off" /></div><ul class="chosen-results"></ul></div>'

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
    @container.bind 'touchstart.chosen', (evt) => this.container_mousedown(evt); evt.preventDefault()
    @container.bind 'touchend.chosen', (evt) => this.container_mouseup(evt); evt.preventDefault()

    @container.bind 'mousedown.chosen', (evt) => this.container_mousedown(evt); return
    @container.bind 'mouseup.chosen', (evt) => this.container_mouseup(evt); return
    @container.bind 'mouseenter.chosen', (evt) => this.mouse_enter(evt); return
    @container.bind 'mouseleave.chosen', (evt) => this.mouse_leave(evt); return

    @search_results.bind 'mouseup.chosen', (evt) => this.search_results_mouseup(evt); return
    @search_results.bind 'mouseover.chosen', (evt) => this.search_results_mouseover(evt); return
    @search_results.bind 'mouseout.chosen', (evt) => this.search_results_mouseout(evt); return
    @search_results.bind 'mousewheel.chosen DOMMouseScroll.chosen', (evt) => this.search_results_mousewheel(evt); return

    @search_results.bind 'touchstart.chosen', (evt) => this.search_results_touchstart(evt); return
    @search_results.bind 'touchmove.chosen', (evt) => this.search_results_touchmove(evt); return
    @search_results.bind 'touchend.chosen', (evt) => this.search_results_touchend(evt); return

    @form_field_jq.bind "chosen:updated.chosen", (evt) => this.results_update_field(evt); return
    @form_field_jq.bind "chosen:activate.chosen", (evt) => this.activate_field(evt); return
    @form_field_jq.bind "chosen:open.chosen", (evt) => this.container_mousedown(evt); return
    @form_field_jq.bind "chosen:close.chosen", (evt) => this.input_blur(evt); return

    @search_field.bind 'blur.chosen', (evt) => this.input_blur(evt); return
    @search_field.bind 'keyup.chosen', (evt) => this.keyup_checker(evt); return
    @search_field.bind 'keydown.chosen', (evt) => this.keydown_checker(evt); return
    @search_field.bind 'focus.chosen', (evt) => this.input_focus(evt); return
    @search_field.bind 'cut.chosen', (evt) => this.clipboard_event_checker(evt); return
    @search_field.bind 'paste.chosen', (evt) => this.clipboard_event_checker(evt); return

    if @is_multiple
      @search_choices.bind 'click.chosen', (evt) => this.choices_click(evt); return
    else
      @container.bind 'click.chosen', (evt) -> evt.preventDefault(); return # gobble click of anchor

  destroy: ->
    $(@container[0].ownerDocument).unbind "click.chosen", @click_test_action
    if @search_field[0].tabIndex
      @form_field_jq[0].tabIndex = @search_field[0].tabIndex

    @container.remove()
    @form_field_jq.removeData('chosen')
    @form_field_jq.show()

  search_field_disabled: ->
    @is_disabled = @form_field_jq[0].disabled
    if(@is_disabled)
      @container.addClass 'chosen-disabled'
      @search_field[0].disabled = true
      @selected_item.unbind "focus.chosen", @activate_action if !@is_multiple
      this.close_field()
    else
      @container.removeClass 'chosen-disabled'
      @search_field[0].disabled = false
      @selected_item.bind "focus.chosen", @activate_action if !@is_multiple

  container_mousedown: (evt) ->
    if !@is_disabled
      if evt and evt.type is "mousedown" and not @results_showing
        evt.preventDefault()

      if not (evt? and ($ evt.target).hasClass "search-choice-close")
        if not @active_field
          @search_field.val "" if @is_multiple
          $(@container[0].ownerDocument).bind 'click.chosen', @click_test_action
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
    $(@container[0].ownerDocument).unbind "click.chosen", @click_test_action

    @active_field = false
    this.results_hide()

    @container.removeClass "chosen-container-active"
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
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
    else if not @is_multiple
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

    @container.addClass "chosen-with-drop"
    @results_showing = true

    @search_field.focus()
    @search_field.val @search_field.val()

    this.winnow_results()
    @form_field_jq.trigger("chosen:showing_dropdown", {chosen: this})

  update_results_content: (content) ->
    @search_results.html content

  results_hide: ->
    if @results_showing
      this.result_clear_highlight()

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
      @form_field_label.bind 'click.chosen', (evt) => if @is_multiple then this.container_mousedown(evt) else this.activate_field()

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
    this.result_clear_highlight() if $(evt.target).hasClass "active-result" or $(evt.target).parents('.active-result').first()

  choice_build: (item) ->
    choice = $('<li />', { class: "search-choice" }).html("<span>#{this.choice_label(item)}</span>")

    if item.disabled
      choice.addClass 'search-choice-disabled'
    else
      close_link = $('<a />', { class: 'search-choice-close', 'data-option-array-index': item.array_index })
      close_link.bind 'click.chosen', (evt) => this.choice_destroy_link_click(evt)
      choice.append close_link

    @search_container.before  choice

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy $(evt.target) unless @is_disabled

  choice_destroy: (link) ->
    if this.result_deselect( link[0].getAttribute("data-option-array-index") )
      this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and @search_field.val().length < 1

      link.parents('li').first().remove()

      this.search_field_scale()

  results_reset: ->
    this.reset_single_select_options()
    @form_field.options[0].selected = true
    this.single_set_selected_text()
    this.show_search_field_default()
    this.results_reset_cleanup()
    @form_field_jq.trigger "change"
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

      if @is_multiple
        this.choice_build item
      else
        this.single_set_selected_text(this.choice_label(item))

      this.results_hide() unless (evt.metaKey or evt.ctrlKey) and @is_multiple
      this.show_search_field_default()

      @form_field_jq.trigger "change", {'selected': @form_field.options[item.options_index].value} if @is_multiple || @form_field.selectedIndex != @current_selectedIndex
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

      @form_field_jq.trigger "change", {deselected: @form_field.options[result_data.options_index].value}
      this.search_field_scale()

      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
    @selected_item.find("span").first().after "<abbr class=\"search-choice-close\"></abbr>" unless @selected_item.find("abbr").length
    @selected_item.addClass("chosen-single-with-deselect")

  get_search_text: ->
    $('<div/>').text($.trim(@search_field.val())).html()

  winnow_results_set_highlight: ->
    selected_results = if not @is_multiple then @search_results.find(".result-selected.active-result") else []
    do_high = if selected_results.length then selected_results.first() else @search_results.find(".active-result").first()

    this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    no_results_html = $('<li class="no-results">' + @results_none_found + ' "<span></span>"</li>')
    no_results_html.find("span").first().html(terms)

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

  keydown_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()

    this.clear_backstroke() if stroke != 8 and this.pending_backstroke

    switch stroke
      when 8
        @backstroke_length = this.search_field.val().length
        break
      when 9
        this.result_select(evt) if this.results_showing and not @is_multiple
        @mouse_on_container = false
        break
      when 13
        evt.preventDefault() if this.results_showing
        break
      when 32
        evt.preventDefault() if @disable_search
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
        style_block += style + ":" + @search_field.css(style) + ";"

      div = $('<div />', { 'style' : style_block })
      div.text @search_field.val()
      $('body').append div

      w = div.width() + 25
      div.remove()

      f_width = @container.outerWidth()

      if( w > f_width - 10 )
        w = f_width - 10

      @search_field.css({'width': w + 'px'})
