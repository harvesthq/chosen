root = this
$ = jQuery

$.fn.extend({
  chosen: (options) ->
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    # Continue on if running IE document type but in compatibility mode
    return this unless AbstractChosen.browser_is_supported()
    this.each((input_field) ->
      $this = $ this
      $this.data('chosen', new Chosen(this, options)) unless $this.hasClass "chzn-done"
    )
})

class Chosen extends AbstractChosen

  setup: ->
    @form_field_jq = $ @form_field
    @current_selectedIndex = @form_field.selectedIndex
    @is_rtl = @form_field_jq.hasClass "chzn-rtl"

  finish_setup: ->
    @form_field_jq.addClass "chzn-done"

  set_up_html: ->
    @container_id = if @form_field.id.length then @form_field.id.replace(/[^\w]/g, '_') else this.generate_field_id()
    @container_id += "_chzn"

    container_classes = ["chzn-container"]
    container_classes.push "chzn-container-" + (if @is_multiple then "multi" else "single")
    container_classes.push @form_field.className if @inherit_select_classes && @form_field.className
    container_classes.push "chzn-rtl" if @is_rtl

    container_props =
      'id': @container_id
      'class': container_classes.join ' '
      'style': "width: #{this.container_width()};"
      'title': @form_field.title

    @container = ($ "<div />", container_props)

    if @is_multiple
      @container.html '<ul class="chzn-choices"><li class="search-field"><input type="text" value="' + @default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chzn-drop"><ul class="chzn-results"></ul></div>'
    else
      @container.html '<a href="javascript:void(0)" class="chzn-single chzn-default" tabindex="-1"><span>' + @default_text + '</span><div><b></b></div></a><div class="chzn-drop"><div class="chzn-search"><input type="text" autocomplete="off" /></div><ul class="chzn-results"></ul></div>'

    @form_field_jq.hide().after @container
    @dropdown = @container.find('div.chzn-drop').first()

    @search_field = @container.find('input').first()
    @search_results = @container.find('ul.chzn-results').first()
    this.search_field_scale()

    @search_no_results = @container.find('li.no-results').first()

    if @is_multiple
      @search_choices = @container.find('ul.chzn-choices').first()
      @search_container = @container.find('li.search-field').first()
    else
      @search_container = @container.find('div.chzn-search').first()
      @selected_item = @container.find('.chzn-single').first()
    
    this.results_build()
    this.set_tab_index()
    this.set_label_behavior()
    @form_field_jq.trigger("liszt:ready", {chosen: this})

  register_observers: ->
    @container.mousedown (evt) => this.container_mousedown(evt); return
    @container.mouseup (evt) => this.container_mouseup(evt); return
    @container.mouseenter (evt) => this.mouse_enter(evt); return
    @container.mouseleave (evt) => this.mouse_leave(evt); return

    @search_results.mouseup (evt) => this.search_results_mouseup(evt); return
    @search_results.mouseover (evt) => this.search_results_mouseover(evt); return
    @search_results.mouseout (evt) => this.search_results_mouseout(evt); return
    @search_results.bind 'mousewheel DOMMouseScroll', (evt) => this.search_results_mousewheel(evt); return

    @form_field_jq.bind "liszt:updated", (evt) => this.results_update_field(evt); return
    @form_field_jq.bind "liszt:activate", (evt) => this.activate_field(evt); return
    @form_field_jq.bind "liszt:open", (evt) => this.container_mousedown(evt); return

    @search_field.blur (evt) => this.input_blur(evt); return
    @search_field.keyup (evt) => this.keyup_checker(evt); return
    @search_field.keydown (evt) => this.keydown_checker(evt); return
    @search_field.focus (evt) => this.input_focus(evt); return

    if @is_multiple
      @search_choices.click (evt) => this.choices_click(evt); return
    else
      @container.click (evt) => evt.preventDefault(); return # gobble click of anchor

  search_field_disabled: ->
    @is_disabled = @form_field_jq[0].disabled
    if(@is_disabled)
      @container.addClass 'chzn-disabled'
      @search_field[0].disabled = true
      @selected_item.unbind "focus", @activate_action if !@is_multiple
      this.close_field()
    else
      @container.removeClass 'chzn-disabled'
      @search_field[0].disabled = false
      @selected_item.bind "focus", @activate_action if !@is_multiple

  container_mousedown: (evt) ->
    if !@is_disabled
      if evt and evt.type is "mousedown" and not @results_showing
        evt.preventDefault()

      if not (evt? and ($ evt.target).hasClass "search-choice-close")
        if not @active_field
          @search_field.val "" if @is_multiple
          $(document).click @click_test_action
          this.results_show()
        else if not @is_multiple and evt and (($(evt.target)[0] == @selected_item[0]) || $(evt.target).parents("a.chzn-single").length)
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
    this.close_field() if not @active_field and @container.hasClass "chzn-container-active"

  close_field: ->
    $(document).unbind "click", @click_test_action

    @active_field = false
    this.results_hide()

    @container.removeClass "chzn-container-active"
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
    @container.addClass "chzn-container-active"
    @active_field = true

    @search_field.val(@search_field.val())
    @search_field.focus()


  test_active_click: (evt) ->
    if $(evt.target).parents('#' + @container_id).length
      @active_field = true
    else
      this.close_field()

  results_build: ->
    @parsing = true
    @selected_option_count = null

    @results_data = root.SelectParser.select_to_array @form_field

    if @is_multiple
      @search_choices.find("li.search-choice").remove()
    else if not @is_multiple
      @selected_item.addClass("chzn-default").find("span").text(@default_text)
      if @disable_search or @form_field.options.length <= @disable_search_threshold
        @search_field.prop('readonly', true)
        @container.addClass "chzn-container-single-nosearch"
      else
        @search_field.prop('readonly', false)
        @container.removeClass "chzn-container-single-nosearch"

    content = ''
    for data in @results_data
      if data.group
        content += this.result_add_group data
      else if !data.empty
        content += this.result_add_option data
        if data.selected and @is_multiple
          this.choice_build data
        else if data.selected and not @is_multiple
          @selected_item.removeClass("chzn-default").find("span").text data.text
          this.single_deselect_control_build() if @allow_single_deselect

    this.search_field_disabled()
    this.show_search_field_default()
    this.search_field_scale()

    @search_results.html content
    @parsing = false

  result_add_group: (group) ->
    group.dom_id = @container_id + "_g_" + group.array_index
    '<li id="' + group.dom_id + '" class="group-result">' + $("<div />").text(group.label).html() + '</li>'

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
      @form_field_jq.trigger("liszt:maxselected", {chosen: this})
      return false

    @container.addClass "chzn-with-drop"
    @form_field_jq.trigger("liszt:showing_dropdown", {chosen: this})

    @results_showing = true

    @search_field.focus()
    @search_field.val @search_field.val()

    this.winnow_results()

  results_hide: ->
    if @results_showing
      this.result_clear_highlight()

      @container.removeClass "chzn-with-drop"
      @form_field_jq.trigger("liszt:hiding_dropdown", {chosen: this})

    @results_showing = false


  set_tab_index: (el) ->
    if @form_field_jq.attr "tabindex"
      ti = @form_field_jq.attr "tabindex"
      @form_field_jq.attr "tabindex", -1
      @search_field.attr "tabindex", ti

  set_label_behavior: ->
    @form_field_label = @form_field_jq.parents("label") # first check for a parent label
    if not @form_field_label.length and @form_field.id.length
      @form_field_label = $("label[for='#{@form_field.id}']") #next check for a for=#{id}

    if @form_field_label.length > 0
      @form_field_label.click (evt) => if @is_multiple then this.container_mousedown(evt) else this.activate_field()

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
    choice = $('<li />', { class: "search-choice" }).html("<span>#{item.html}</span>")

    if item.disabled
      choice.addClass 'search-choice-disabled'
    else
      close_link = $('<a />', { href: '#', class: 'search-choice-close',  rel: item.array_index })
      close_link.click (evt) => this.choice_destroy_link_click(evt)
      choice.append close_link
    
    @search_container.before  choice

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy $(evt.target) unless @is_disabled

  choice_destroy: (link) ->
    if this.result_deselect (link.attr "rel")
      this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and @search_field.val().length < 1

      link.parents('li').first().remove()

      this.search_field_scale()

  results_reset: ->
    @form_field.options[0].selected = true
    @selected_option_count = null
    @selected_item.find("span").text @default_text
    @selected_item.addClass("chzn-default") if not @is_multiple
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
      high_id = high.attr "id"

      this.result_clear_highlight()

      if @is_multiple and @max_selected_options <= this.choices_count()
        @form_field_jq.trigger("liszt:maxselected", {chosen: this})
        return false

      if @is_multiple
        high.removeClass("active-result")
      else
        @search_results.find(".result-selected").removeClass "result-selected"
        @result_single_selected = high
        @selected_item.removeClass("chzn-default")

      high.addClass "result-selected"

      position = high_id.substr(high_id.lastIndexOf("_") + 1 )
      item = @results_data[position]
      item.selected = true

      @form_field.options[item.options_index].selected = true
      @selected_option_count = null

      if @is_multiple
        this.choice_build item
      else
        @selected_item.find("span").first().text item.text
        this.single_deselect_control_build() if @allow_single_deselect

      this.results_hide() unless (evt.metaKey or evt.ctrlKey) and @is_multiple

      @search_field.val ""

      @form_field_jq.trigger "change", {'selected': @form_field.options[item.options_index].value} if @is_multiple || @form_field.selectedIndex != @current_selectedIndex
      @current_selectedIndex = @form_field.selectedIndex
      this.search_field_scale()

  result_activate: (el, option) ->
    if option.disabled
      el.addClass("disabled-result")
    else if @is_multiple and option.selected
      el.addClass("result-selected")
    else
      el.addClass("active-result")

  result_deactivate: (el) ->
    el.removeClass("active-result result-selected disabled-result")

  result_deselect: (pos) ->
    result_data = @results_data[pos]

    if not @form_field.options[result_data.options_index].disabled
      result_data.selected = false

      @form_field.options[result_data.options_index].selected = false
      @selected_option_count = null

      result = $("#" + @container_id + "_o_" + pos)
      result.removeClass("result-selected").addClass("active-result").show()

      this.result_clear_highlight()
      this.winnow_results()

      @form_field_jq.trigger "change", {deselected: @form_field.options[result_data.options_index].value}
      this.search_field_scale()

      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
    @selected_item.find("span").first().after "<abbr class=\"search-choice-close\"></abbr>" unless @selected_item.find("abbr").length
    @selected_item.addClass("chzn-single-with-deselect")

  winnow_results: ->
    this.no_results_clear()

    results = 0

    searchText = if @search_field.val() is @default_text then "" else $('<div/>').text($.trim(@search_field.val())).html()
    regexAnchor = if @search_contains then "" else "^"
    regex = new RegExp(regexAnchor + searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')
    zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')

    for option in @results_data
      if not option.empty
        if option.group
          $('#' + option.dom_id).css('display', 'none')
        else
          found = false
          result_id = option.dom_id
          result = $("#" + result_id)

          if regex.test option.html
            found = true
            results += 1
          else if @enable_split_word_search and (option.html.indexOf(" ") >= 0 or option.html.indexOf("[") == 0)
            #TODO: replace this substitution of /\[\]/ with a list of characters to skip.
            parts = option.html.replace(/\[|\]/g, "").split(" ")
            if parts.length
              for part in parts
                if regex.test part
                  found = true
                  results += 1

          if found
            if searchText.length
              startpos = option.html.search zregex
              text = option.html.substr(0, startpos + searchText.length) + '</em>' + option.html.substr(startpos + searchText.length)
              text = text.substr(0, startpos) + '<em>' + text.substr(startpos)
            else
              text = option.html

            result.html(text)
            this.result_activate result, option

            $("#" + @results_data[option.group_array_index].dom_id).css('display', 'list-item') if option.group_array_index?
          else
            this.result_clear_highlight() if @result_highlight and result_id is @result_highlight.attr 'id'
            this.result_deactivate result

    if results < 1 and searchText.length
      this.no_results searchText
    else
      this.winnow_results_set_highlight()

  winnow_results_set_highlight: ->
    if not @result_highlight

      selected_results = if not @is_multiple then @search_results.find(".result-selected.active-result") else []
      do_high = if selected_results.length then selected_results.first() else @search_results.find(".active-result").first()

      this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    no_results_html = $('<li class="no-results">' + @results_none_found + ' "<span></span>"</li>')
    no_results_html.find("span").first().html(terms)

    @search_results.append no_results_html

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
        style_block += style + ":" + @search_field.css(style) + ";"

      div = $('<div />', { 'style' : style_block })
      div.text @search_field.val()
      $('body').append div

      w = div.width() + 25
      div.remove()

      @f_width = @container.outerWidth() unless @f_width

      if( w > @f_width-10 )
        w = @f_width - 10

      @search_field.css({'width': w + 'px'})
  
  generate_random_id: ->
    string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char()
    while $("#" + string).length > 0
      string += this.generate_random_char()
    string

root.Chosen = Chosen
