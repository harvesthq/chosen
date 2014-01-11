# Extending the Element prototype to cover for jQuery
if not Element.prototype.matches then Element.prototype.matches = (selector) ->
  matches = this.webkitMatchesSelector or this.mozMatchesSelector or this.msMatchesSelector or this.oMatchesSelector
  return matches.call this, selector

Element.prototype.parents = (selector) ->
  parents = []
  p = this.parentNode
  while p not in [document, null]
    o = p
    parents.push o
    p = o.parentNode
  if selector
    parents.filter (parent) ->
      parent.matches selector
  return parents

Element.prototype.closest = (selector) ->
  p = this.parentNode
  while p isnt document and not p.matches selector
    p = p.parentNode
  return p

if CustomEvent then Element.prototype.trigger = (eventName, data) ->
  params = bubbles: true, cancelable: true, detail: data
  evt = if data? then (new CustomEvent eventName, params) else (new Event)
  this.dispatchEvent evt
else
#  cf. http://stackoverflow.com/questions/5342917/custom-events-in-ie-without-using-libraries
#    & http://www.kaizou.org/2010/03/generating-custom-javascript-events/
#    & https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent
  Element.prototype.trigger = (eventName, data) ->
    params = bubbles: true, cancelable: true, detail: data
    evt = document.createEvent 'CustomEvent'
    evt.initCustomEvent eventName, params.bubbles, params.cancelable, params.detail
#    if data?
#      for key, value of data
#        evt[key] = value
    this.dispatchEvent evt

if not DOMTokenList or not Element.prototype.classList then Element.prototype.classList =
  add: (className) ->
  remove: (className) ->
  contains: (className) ->

Array.prototype.classList =
  add: (className) ->
    this.forEach (el) ->
      el.classList.add className
  , remove: (className) ->
    this.forEach (el) ->
      el.classList.remove className

NodeList.prototype.classList =
  add: (className) ->
    [].forEach.call [].slice.call(this), (node) ->
      node.classList.add className
  , remove: (className) ->
    [].forEach.call [].slice.call(this), (node) ->
      node.classList.remove className

Element.prototype.nextAll = (selector) ->
  s = this.parentNode.querySelectorAll selector
  idx = s.indexOf this
  return s[(idx + 1)..]

Element.prototype.prevAll = (selector) ->
  s = this.parentNode.querySelectorAll(selector).reverse()
  idx = s.indexOf this
  return s[(idx + 1)..]

Element.prototype.siblings = () ->
  s = []
  el = this.nextElementSibling
  while el isnt null
    s.push el
    el = el.nextElementSibling
  return s

Element.prototype.before = (element) ->
  this.parentNode.insertBefore element, this
  return this

Element.prototype.after = (element) ->
  this.parentNode.insertBefore element, this.nextElementSibling
  return this







class Chosen extends AbstractChosen

  setup: ->
    @current_selectedIndex = @form_field.selectedIndex
    @is_rtl = @form_field.classList.contains "chosen-rtl"

  set_up_html: ->
    container_classes = ["chosen-container"]
    container_classes.push "chosen-container-" + (if @is_multiple then "multi" else "single")
    container_classes.push @form_field.className if @inherit_select_classes && @form_field.className
    container_classes.push "chosen-rtl" if @is_rtl

    @container = document.createElement "div"
    @container.id = @form_field.id.replace(/[^\w]/g, '_') + "_chosen" if @form_field.id.length
    @container.className = container_classes.join ' '
    @container.style.width = this.container_width()
    @container.title = @form_field.title

    if @is_multiple
      @container.innerHTML = '<ul class="chosen-choices"><li class="search-field"><input type="text" value="' + @default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chosen-drop"><ul class="chosen-results"></ul></div>'
    else
      @container.innerHTML = '<a class="chosen-single chosen-default" tabindex="-1"><span>' + @default_text + '</span><div><b></b></div></a><div class="chosen-drop"><div class="chosen-search"><input type="text" autocomplete="off" /></div><ul class="chosen-results"></ul></div>'

    @form_field.style.display = 'none'
    @form_field.after @container
    @dropdown = @container.querySelector 'div.chosen-drop'

    @search_field = @container.querySelector 'input'
    @search_results = @container.querySelector 'ul.chosen-results'
    this.search_field_scale()

    @search_no_results = @container.querySelector 'li.no-results'

    if @is_multiple
      @search_choices = @container.querySelector 'ul.chosen-choices'
      @search_container = @container.querySelector 'li.search-field'
    else
      @search_container = @container.querySelector 'div.chosen-search'
      @selected_item = @container.querySelector '.chosen-single'

    this.results_build()
    this.set_tab_index()
    this.set_label_behavior()
    @form_field.trigger 'chosen:ready', {chosen: this}

  register_observers: ->
    @container.addEventListener 'mousedown', (evt) => this.container_mousedown(evt); return
    @container.addEventListener 'mouseup', (evt) => this.container_mouseup(evt); return
    @container.addEventListener 'mouseenter', (evt) => this.mouse_enter(evt); return
    @container.addEventListener 'mouseleave', (evt) => this.mouse_leave(evt); return

    @search_results.addEventListener 'mouseup', (evt) => this.search_results_mouseup(evt); return
    @search_results.addEventListener 'mouseover', (evt) => this.search_results_mouseover(evt); return
    @search_results.addEventListener 'mouseout', (evt) => this.search_results_mouseout(evt); return
    @search_results.addEventListener 'mousewheel', (evt) => this.search_results_mousewheel(evt); return
    @search_results.addEventListener 'DOMMouseScroll', (evt) => this.search_results_mousewheel(evt); return

    @search_results.addEventListener 'touchstart', (evt) => this.search_results_touchstart(evt); return
    @search_results.addEventListener 'touchmove', (evt) => this.search_results_touchmove(evt); return
    @search_results.addEventListener 'touchend', (evt) => this.search_results_touchend(evt); return

    @form_field.addEventListener "chosen:updated", (evt) => this.results_update_field(evt); return
    @form_field.addEventListener "chosen:activate", (evt) => this.activate_field(evt); return
    @form_field.addEventListener "chosen:open", (evt) => this.container_mousedown(evt); return
    @form_field.addEventListener "chosen:close", (evt) => this.input_blur(evt); return

    @search_field.addEventListener 'blur', (evt) => this.input_blur(evt); return
    @search_field.addEventListener 'keyup', (evt) => this.keyup_checker(evt); return
    @search_field.addEventListener 'keydown', (evt) => this.keydown_checker(evt); return
    @search_field.addEventListener 'focus', (evt) => this.input_focus(evt); return

    if @is_multiple
      @search_choices.addEventListener 'click', (evt) => this.choices_click(evt); return
    else
      @container.addEventListener 'click', (evt) -> evt.preventDefault(); return # gobble click of anchor

  destroy: ->
    document.removeEventListener "click", @click_test_action

    @container.remove()
    @form_field.removeAttribute 'data-chosen'
    @form_field.style.display = ''

  search_field_disabled: ->
    @is_disabled = @form_field.disabled
    if(@is_disabled)
      @container.classList.add 'chosen-disabled'
      @search_field.disabled = true
      @selected_item.removeEventListener "focus", @activate_action if !@is_multiple
      this.close_field()
    else
      @container.classList.remove 'chosen-disabled'
      @search_field.disabled = false
      @selected_item.addEventListener "focus", @activate_action if !@is_multiple

  container_mousedown: (evt) ->
    if !@is_disabled
      if evt and evt.type is "mousedown" and not @results_showing
        evt.preventDefault()

      if not (evt? and evt.target.classList.contains "search-choice-close")
        if not @active_field
          @search_field.value = "" if @is_multiple
          document.addEventListener 'click', @click_test_action
          this.results_show()
        else if not @is_multiple and evt and ((evt.target == @selected_item) or (evt.target.parents 'a.chosen-single').length)
          evt.preventDefault()
          this.results_toggle()

        this.activate_field()

  container_mouseup: (evt) ->
    this.results_reset(evt) if evt.target.nodeName is "ABBR" and not @is_disabled

  search_results_mousewheel: (evt) ->
    delta = -evt.originalEvent.wheelDelta or evt.originalEvent.detail if evt.originalEvent
    if delta?
      evt.preventDefault()
      delta = delta * 40 if evt.type is 'DOMMouseScroll'
      @search_results.scrollTop = delta + this.scrollTop @search_results

  blur_test: (evt) ->
    this.close_field() if not @active_field and @container.classList.contains "chosen-container-active"

  close_field: ->
    document.removeEventListener "click", @click_test_action

    @active_field = false
    this.results_hide()

    @container.classList.remove "chosen-container-active"
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
    @container.classList.add "chosen-container-active"
    @active_field = true

    @search_field.focus()

  test_active_click: (evt) ->
    active_container = evt.target.closest '.chosen-container'
    if active_container and @container == active_container
      @active_field = true
    else
      this.close_field()

  results_build: ->
    @parsing = true
    @selected_option_count = null

    @results_data = SelectParser.select_to_array @form_field

    if @is_multiple
      [].forEach.call @search_choices.querySelectorAll("li.search-choice"), (el) ->
        el.remove()
    else if not @is_multiple
      this.single_set_selected_text()
      if @disable_search or @form_field.options.length <= @disable_search_threshold
        @search_field.readOnly = true
        @container.classList.add "chosen-container-single-nosearch"
      else
        @search_field.readOnly = false
        @container.classList.remove "chosen-container-single-nosearch"

    this.update_results_content this.results_option_build({first:true})

    this.search_field_disabled()
    this.show_search_field_default()
    this.search_field_scale()

    @parsing = false

  result_do_highlight: (el) ->
    if el
      this.result_clear_highlight()

      @result_highlight = el
      @result_highlight.classList.add "highlighted"

      maxHeight = parseInt @search_results.style.maxHeight, 10
      visible_top = @search_results.scrollTop
      visible_bottom = maxHeight + visible_top

      high_top = @result_highlight.offsetTop + @search_results.scrollTop
      high_bottom = high_top + @result_highlight.offsetHeight

      if high_bottom >= visible_bottom
        @search_results.scrollTop = if (high_bottom - maxHeight) > 0 then (high_bottom - maxHeight) else 0
      else if high_top < visible_top
        @search_results.scrollTop = high_top

  result_clear_highlight: ->
    @result_highlight.classList.remove "highlighted" if @result_highlight
    @result_highlight = null

  results_show: ->
    if @is_multiple and @max_selected_options <= this.choices_count()
      @form_field.trigger 'chosen:maxselected', {chosen: this}
      return false

    @container.classList.add "chosen-with-drop"
    @form_field.trigger 'chosen:showing_dropdown', {chosen: this}

    @results_showing = true

    @search_field.focus()

    this.winnow_results()

  update_results_content: (content) ->
    @search_results.innerHTML = content

  results_hide: ->
    if @results_showing
      this.result_clear_highlight()

      @container.classList.remove "chosen-with-drop"
      @form_field.trigger 'chosen:hiding_dropdown', {chosen: this}

    @results_showing = false

  set_tab_index: (el) ->
    if @form_field.tabIndex
      ti = @form_field.tabIndex
      @form_field.tabIndex = -1
      @search_field.tabIndex = ti

  set_label_behavior: ->
    @form_field_label = @form_field.parents "label" # first check for a parent label
    if not @form_field_label.length and @form_field.id.length
      @form_field_label = document.body.querySelectorAll "label[for='#{@form_field.id}']" #next check for a for=#{id}

    if @form_field_label.length > 0
      @form_field_label[0].addEventListener 'click', (evt) => if @is_multiple then this.container_mousedown(evt) else this.activate_field()

  show_search_field_default: ->
    if @is_multiple and this.choices_count() < 1 and not @active_field
      @search_field.value = @default_text
      @search_field.classList.add "default"
    else
      @search_field.value = ""
      @search_field.classList.remove "default"

  search_results_mouseup: (evt) ->
    target = if evt.target.classList.contains "active-result" then evt.target else evt.target.closest ".active-result"
    if target
      @result_highlight = target
      this.result_select(evt)
      @search_field.focus()

  search_results_mouseover: (evt) ->
    target = if evt.target.classList.contains "active-result" then evt.target else evt.target.closest ".active-result"
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if evt.target.classList.contains "active-result" or evt.target.closest '.active-result'

  choice_build: (item) ->
    choice = document.createElement 'li'
    choice.classList.add('search-choice')
    choice.innerHTML = "<span>#{item.html}</span>"

    if item.disabled
      choice.classList.add 'search-choice-disabled'
    else
      close_link = document.createElement 'a'
      close_link.classList.add 'search-choice-close'
      close_link.setAttribute 'data-option-array-index', item.array_index
      close_link.addEventListener 'click', (evt) => this.choice_destroy_link_click(evt)
      choice.appendChild close_link

    @search_container.before choice

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy evt.target unless @is_disabled

  choice_destroy: (link) ->
    if this.result_deselect( link.getAttribute "data-option-array-index" )
      this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and @search_field.value.length < 1

      (link.closest 'li').remove()

      this.search_field_scale()

  results_reset: ->
    this.reset_single_select_options()
    @form_field.options.selected = true
    this.single_set_selected_text()
    this.show_search_field_default()
    this.results_reset_cleanup()
    @form_field.trigger 'change'
    this.results_hide() if @active_field

  results_reset_cleanup: ->
    @current_selectedIndex = @form_field.selectedIndex
    [].forEach.call @selected_item.querySelectorAll("abbr"), (el) ->
      el.remove()

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight

      this.result_clear_highlight()

      if @is_multiple and @max_selected_options <= this.choices_count()
        @form_field.trigger 'chosen:maxselected', {chosen: this}
        return false

      if @is_multiple
        high.classList.remove "active-result"
      else
        this.reset_single_select_options()

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

      @form_field.trigger 'change', {'selected': @form_field.options[item.options_index].value} if @is_multiple or @form_field.selectedIndex != @current_selectedIndex
      @current_selectedIndex = @form_field.selectedIndex
      this.search_field_scale()

  single_set_selected_text: (text=@default_text) ->
    if text is @default_text
      @selected_item.classList.add "chosen-default"
    else
      this.single_deselect_control_build()
      @selected_item.classList.remove "chosen-default"

    @selected_item.querySelector("span").innerHTML = text

  result_deselect: (pos) ->
    result_data = @results_data[pos]

    if not @form_field.options[result_data.options_index].disabled
      result_data.selected = false

      @form_field.options[result_data.options_index].selected = false
      @selected_option_count = null

      this.result_clear_highlight()
      this.winnow_results() if @results_showing

      @form_field.trigger "change", {deselected: @form_field.options[result_data.options_index].value}
      this.search_field_scale()

      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
    abbr = document.createElement 'abbr'
    abbr.setAttribute 'class', 'search-choice-close'
    @selected_item.querySelector("span").after abbr unless @selected_item.querySelectorAll("abbr").length
    @selected_item.classList.add "chosen-single-with-deselect"

  get_search_text: ->
    if @search_field.value is @default_text then "" else @search_field.value.trim()

  winnow_results_set_highlight: ->
    selected_results = if not @is_multiple then @search_results.querySelectorAll(".result-selected.active-result") else []
    do_high = if selected_results.length then selected_results else @search_results.querySelectorAll(".active-result")

    this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    no_results_html = document.createElement('li')
    no_results_html.classList.add 'no-results'
    no_results_html.innerHTML = @results_none_found + "<span></span>"
    no_results_html.querySelector("span").innerHTML = terms

    @search_results.appendChild no_results_html

  no_results_clear: ->
    [].forEach.call @search_results.querySelectorAll(".no-results"), (el) ->
      el.remove()

  keydown_arrow: ->
    if @results_showing and @result_highlight
      next_sib = @result_highlight.nextAll("li.active-result")[0]
      this.result_do_highlight next_sib if next_sib
    else
      this.results_show()

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      prev_sibs = @result_highlight.prevAll "li.active-result"

      if prev_sibs.length
        this.result_do_highlight prev_sibs
      else
        this.results_hide() if this.choices_count() > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.querySelector("a")
      this.clear_backstroke()
    else
      sibs = @search_container.siblings "li.search-choice"
      next_available_destroy = sibs[sibs.length - 1]
      if next_available_destroy and not next_available_destroy.classList.contains("search-choice-disabled")
        @pending_backstroke = next_available_destroy
        if @single_backstroke_delete
          @keydown_backstroke()
        else
          @pending_backstroke.classList.add "search-choice-focus"

  clear_backstroke: ->
    @pending_backstroke.classList.remove "search-choice-focus" if @pending_backstroke
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

      style_block = "position:absolute; left: -1000px; top: -1000px;" # display:none;"
      styles = ['font-size','font-style', 'font-weight', 'font-family','line-height', 'text-transform', 'letter-spacing']
      stylesCamel = ['fontSize','fontStyle', 'fontWeight', 'fontFamily','lineHeight', 'textTransform', 'letterSpacing']

      for style in styles
        style_block += style + ":" + @search_field.style[stylesCamel[styles.indexOf(style)]] + ";"

      div = document.createElement 'div'
      div.setAttribute 'style', style_block
      div.innerText = @search_field.value
      document.body.appendChild div

      w = div.clientWidth + 25
      div.remove()

      f_width = @container.offsetWidth

      if(w > f_width - 10)
        w = f_width - 10

      @search_field.style.width = w + 'px'




Element.prototype.chosen = (options) ->
  # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
  # Continue on if running IE document type but in compatibility mode
  return this unless AbstractChosen.browser_is_supported()
  chosen = this.getAttribute('data-chosen')
  if options is 'destroy' && chosen
    chosen.destroy()
  else unless chosen
    this.getAttribute('data-chosen', new Chosen(this, options))
  return
