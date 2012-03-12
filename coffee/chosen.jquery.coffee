###
Chosen source: generate output using 'cake build'
Copyright (c) 2011 by Harvest
###
root = this
$ = jQuery

$.fn.extend({
  chosen: (options) ->
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    return this if $.browser.msie and ($.browser.version is "6.0" or  $.browser.version is "7.0")
    $(this).each((input_field) ->
      new Chosen(this, options) unless ($ this).hasClass "chzn-done"
    )
})

class Chosen extends AbstractChosen

  setup: ->
    @form_field_jq = $ @form_field
    @is_rtl = @form_field_jq.hasClass "chzn-rtl"

  finish_setup: ->
    @form_field_jq.addClass "chzn-done"

  set_up_html: ->
    @container_id = if @form_field.id.length then @form_field.id.replace(/(:|\.)/g, '_') else this.generate_field_id()
    @container_id += "_chzn"
    
    @f_width = @form_field_jq.outerWidth()

    @default_text = if @form_field_jq.attr 'data-placeholder' then @form_field_jq.attr 'data-placeholder' else @default_text_default
    
    container_div = $("<div />").attr({
      id: @container_id
      class: "chzn-container#{ if @is_rtl then ' chzn-rtl' else '' }"
      style: 'width: ' + (@f_width) + 'px;' #use parens around @f_width so coffeescript doesn't think + ' px' is a function parameter
    })
    
    if @is_multiple
      container_div.html '<ul class="chzn-choices"><li class="search-field"><input type="text" value="' + @default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chzn-drop" style="left:-9000px;"><ul class="chzn-results"></ul></div>'
    else
      container_div.html '<a href="javascript:void(0)" class="chzn-single"><span>' + @default_text + '</span><div><b></b></div></a><div class="chzn-drop" style="left:-9000px;"><div class="chzn-search"><input type="text" autocomplete="off" /></div><ul class="chzn-results"></ul></div>'

    @form_field_jq.hide().after container_div
    @container = ($ '#' + @container_id)
    @container.addClass( "chzn-container-" + (if @is_multiple then "multi" else "single") )
    @dropdown = @container.find('div.chzn-drop').filter(':first')
    
    dd_top = @container.height()
    dd_width = (@f_width - get_side_border_padding(@dropdown))
    
    @dropdown.css({"width": dd_width  + "px", "top": dd_top + "px"})

    @search_field = @container.find('input').filter(':first')
    @search_results = @container.find('ul.chzn-results').filter(':first')
    this.search_field_scale()

    @search_no_results = @container.find('li.no-results').filter(':first')
    
    if @is_multiple
      @search_choices = @container.find('ul.chzn-choices').filter(':first')
      @search_container = @container.find('li.search-field').filter(':first')
    else
      @search_container = @container.find('div.chzn-search').filter(':first')
      @selected_item = @container.find('.chzn-single').filter(':first')
      sf_width = dd_width - get_side_border_padding(@search_container) - get_side_border_padding(@search_field)
      @search_field.css( {"width" : sf_width + "px"} )
    
    this.results_build()
    this.set_tab_index()
    @form_field_jq.trigger("liszt:ready", {chosen: this})

  register_observers: ->
    @container.mousedown (evt) => this.container_mousedown(evt)
    @container.mouseup (evt) => this.container_mouseup(evt)
    @container.mouseenter (evt) => this.mouse_enter(evt)
    @container.mouseleave (evt) => this.mouse_leave(evt)
  
    @search_results.mouseup (evt) => this.search_results_mouseup(evt)
    @search_results.mouseover (evt) => this.search_results_mouseover(evt)
    @search_results.mouseout (evt) => this.search_results_mouseout(evt)

    @form_field_jq.bind "liszt:updated", (evt) => this.results_update_field(evt)

    @search_field.blur (evt) => this.input_blur(evt)
    @search_field.keyup (evt) => this.keyup_checker(evt)
    @search_field.keydown (evt) => this.keydown_checker(evt)

    if @is_multiple
      @search_choices.click (evt) => this.choices_click(evt)
      @search_field.focus (evt) => this.input_focus(evt)
    else
      @container.click (evt) => evt.preventDefault() # gobble click of anchor

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
      target_closelink =  if evt? then ($ evt.target).hasClass "search-choice-close" else false
      if evt and evt.type is "mousedown"
        evt.stopPropagation()
      if not @pending_destroy_click and not target_closelink
        if not @active_field
          @search_field.val "" if @is_multiple
          $(document).click @click_test_action
          this.results_show()
        else if not @is_multiple and evt and (($(evt.target)[0] == @selected_item[0]) || $(evt.target).parents("a.chzn-single").length)
          evt.preventDefault()
          this.results_toggle()

        this.activate_field()
      else
        @pending_destroy_click = false

  container_mouseup: (evt) ->
    this.results_reset(evt) if evt.target.nodeName is "ABBR"

  blur_test: (evt) ->
    this.close_field() if not @active_field and @container.hasClass "chzn-container-active"

  close_field: ->
    $(document).unbind "click", @click_test_action
    
    if not @is_multiple
      @selected_item.attr "tabindex", @search_field.attr("tabindex")
      @search_field.attr "tabindex", -1
    
    @active_field = false
    this.results_hide()

    @container.removeClass "chzn-container-active"
    this.winnow_results_clear()
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
    if not @is_multiple and not @active_field
      @search_field.attr "tabindex", (@selected_item.attr "tabindex")
      @selected_item.attr "tabindex", -1

    @container.addClass "chzn-container-active"
    @active_field = true

    @search_field.val(@search_field.val())
    @search_field.focus()

  test_active_click: (evt) ->
    if $(evt.target).parents('#' + @container_id).length
      @active_field = true
    else
      this.close_field()

  init_dom_refs: ->
    for data in @results_data
      if data.dom_id then data.dom_ref = $('#' + data.dom_id)

  results_build: ->
    @parsing = true
    @trie = new InfixTrie(@infix_search, @case_sensitive_search);
    @results_data = root.SelectParser.select_to_array @form_field

    if @is_multiple and @choices > 0
      @search_choices.find("li.search-choice").remove()
      @choices = 0
    else if not @is_multiple
      @selected_item.find("span").text @default_text
      if @form_field.options.length <= @disable_search_threshold
        @container.addClass "chzn-container-single-nosearch"
      else
        @container.removeClass "chzn-container-single-nosearch"

    content = ''
    for option in @results_data
      if option.group
        content += this.result_add_group option
      else if !option.empty
        @trie.add(option.html, option.options_index)
        content += this.result_add_option option
        if option.selected and @is_multiple
          this.choice_build option
        else if option.selected and not @is_multiple
          @selected_item.find("span").text option.text
          this.single_deselect_control_build() if @allow_single_deselect

    this.search_field_disabled()
    this.show_search_field_default()
    this.search_field_scale()
    
    @search_results.html content
    this.init_dom_refs()
    @parsing = false

  result_add_group: (group) ->
    if not group.disabled
      group.dom_id = this.option_get_dom_id(group)
      '<li id="' + group.dom_id + '" class="group-result">' + $("<div />").text(group.label).html() + '</li>'
    else
      ""
  
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
    if not @is_multiple
      @selected_item.addClass "chzn-single-with-drop"
      if @result_single_selected
        this.result_do_highlight( @result_single_selected )

    dd_top = if @is_multiple then @container.height() else (@container.height() - 1)
    @dropdown.css {"top":  dd_top + "px", "left":0}
    @results_showing = true

    @search_field.focus()
    @search_field.val @search_field.val()

    this.winnow_results()

  results_hide: ->
    @selected_item.removeClass "chzn-single-with-drop" unless @is_multiple
    this.result_clear_highlight()
    @dropdown.css {"left":"-9000px"}
    @results_showing = false


  set_tab_index: (el) ->
    if @form_field_jq.attr "tabindex"
      ti = @form_field_jq.attr "tabindex"
      @form_field_jq.attr "tabindex", -1

      if @is_multiple
        @search_field.attr "tabindex", ti
      else
        @selected_item.attr "tabindex", ti
        @search_field.attr "tabindex", -1

  show_search_field_default: ->
    if @is_multiple and @choices < 1 and not @active_field
      @search_field.val(@default_text)
      @search_field.addClass "default"
    else
      @search_field.val("")
      @search_field.removeClass "default"

  search_results_mouseup: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").filter(':first')
    if target.length
      @result_highlight = target
      this.result_select(evt)

  search_results_mouseover: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").filter(':first')
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if $(evt.target).hasClass "active-result" or $(evt.target).parents('.active-result').filter(':first')


  choices_click: (evt) ->
    evt.preventDefault()
    if( @active_field and not($(evt.target).hasClass "search-choice" or $(evt.target).parents('.search-choice').first) and not @results_showing )
      this.results_show()

  choice_build: (item) ->
    choice_id = @container_id + "_c_" + item.array_index
    @choices += 1
    @search_container.before  '<li class="search-choice" id="' + choice_id + '"><span>' + item.html + '</span><a href="javascript:void(0)" class="search-choice-close" rel="' + item.array_index + '"></a></li>'
    link = $('#' + choice_id).find("a").filter(':first')
    link.click (evt) => this.choice_destroy_link_click(evt)

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    if not @is_disabled
      @pending_destroy_click = true
      this.choice_destroy $(evt.target)
    else
      evt.stopPropagation

  choice_destroy: (link) ->
    @choices -= 1
    this.show_search_field_default()

    this.results_hide() if @is_multiple and @choices > 0 and @search_field.val().length < 1

    this.result_deselect (link.attr "rel")
    link.parents('li').filter(':first').remove()

  results_reset: (evt) ->
    @form_field.options[0].selected = true
    @selected_item.find("span").text @default_text
    this.show_search_field_default()
    $(evt.target).remove();
    @form_field_jq.trigger "change"
    this.results_hide() if @active_field

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight
      high_id = high.attr "id"

      position = high_id.substr(high_id.lastIndexOf("_") + 1 )
      option = @results_data[position]
      option.selected = true

      this.result_clear_highlight()

      if @is_multiple
        this.result_set_active_state option, false
      else
        @search_results.find(".result-selected").removeClass "result-selected"
        @result_single_selected = high
      
      high.addClass "result-selected"

      @form_field.options[option.options_index].selected = true

      if @is_multiple
        this.choice_build option
      else
        @selected_item.find("span").filter(':first').text option.text
        this.single_deselect_control_build() if @allow_single_deselect
      
      this.results_hide() unless evt.metaKey and @is_multiple

      @search_field.val ""

      @form_field_jq.trigger "change"
      this.search_field_scale()

  result_set_active_state: (option, active) ->
    if option.active != active
      option.active = active
      option.dom_ref[if active then 'addClass' else 'removeClass']("active-result")

    true

  result_deselect: (pos) ->
    result_data = @results_data[pos]
    result_data.selected = false

    @form_field.options[result_data.options_index].selected = false
    @result_set_active_state result_data.dom_ref, true
    result_data.dom_ref.removeClass("result-selected").show()

    this.result_clear_highlight()
    this.winnow_results()

    @form_field_jq.trigger "change"
    this.search_field_scale()

  single_deselect_control_build: ->
    @selected_item.find("span").filter(':first').after "<abbr class=\"search-choice-close\"></abbr>" if @allow_single_deselect and @selected_item.find("abbr").length < 1

  winnow_results: ->
    this.no_results_clear()

    results = 0

    searchText = if @search_field.val() is @default_text then "" else $('<div/>').text($.trim(@search_field.val())).html()

    if searchText.length
      matches = this.results_filter(searchText)
      zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')

    for option in @results_data
      if not option.disabled and not option.empty
        if option.group
          option.dom_ref.css('display', 'none')
        else if not (@is_multiple and option.selected)
          found = false

          if searchText.length is 0 or option.options_index in matches
            found = true
            results += 1

          if found
            text = option.original_html

            if searchText.length
              startpos = text.search zregex
              text = text.substr(0, startpos + searchText.length) + '</em>' + text.substr(startpos + searchText.length)
              text = text.substr(0, startpos) + '<em>' + text.substr(startpos)

            if text != option.html
              option.html = text
              option.dom_ref.html(this.result_get_html(option))

            this.result_set_active_state option, true

            @results_data[option.group_array_index].dom_ref.css('display', 'list-item') if option.group_array_index?
          else
            this.result_clear_highlight() if @result_highlight and option.dom_id is @result_highlight.attr 'id'
            this.result_set_active_state option, false

    if results < 1 and searchText.length
      this.no_results searchText
    else
      this.winnow_results_set_highlight()

  winnow_results_clear: ->
    @search_field.val ""

    for option in @results_data
      if not option.empty
        if option.dom_ref.hasClass "group-result"
          option.dom_ref.css('display', 'auto')
        else if not @is_multiple or not option.dom_ref.hasClass "result-selected"
          this.result_set_active_state option, true

  winnow_results_set_highlight: ->
    if not @result_highlight

      selected_results = if not @is_multiple then @search_results.find(".result-selected.active-result") else []
      do_high = if selected_results.length then selected_results.filter(':first') else @search_results.find(".active-result").filter(':first')

      this.result_do_highlight do_high if do_high?
  
  no_results: (terms) ->
    no_results_html = $('<li class="no-results">' + @results_none_found + ' "<span></span>"</li>')
    no_results_html.find("span").filter(':first').html(terms)

    @search_results.append no_results_html
  
  no_results_clear: ->
    @search_results.find(".no-results").remove()

  keydown_arrow: ->
    if not @result_highlight
      first_active = @search_results.find("li.active-result").filter(':first')
      this.result_do_highlight $(first_active) if first_active
    else if @results_showing
      next_sib = @result_highlight.nextAll("li.active-result").filter(':first')
      this.result_do_highlight next_sib if next_sib
    this.results_show() if not @results_showing

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      prev_sibs = @result_highlight.prevAll("li.active-result")
      
      if prev_sibs.length
        this.result_do_highlight prev_sibs.filter(':first')
      else
        this.results_hide() if @choices > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.find("a").filter(':first')
      this.clear_backstroke()
    else
      @pending_backstroke = @search_container.siblings("li.search-choice").last()
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
      
      div = $('<div />').attr({ 'style' : style_block })
      div.text @search_field.val()
      $('body').append div

      w = div.width() + 25
      div.remove()

      if( w > @f_width-10 )
        w = @f_width - 10

      @search_field.css({'width': w + 'px'})

      dd_top = @container.height()
      @dropdown.css({"top":  dd_top + "px"})
  
  generate_random_id: ->
    string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char()
    while $("#" + string).length > 0
      string += this.generate_random_char()
    string
    
get_side_border_padding = (elmt) ->
  side_border_padding = elmt.outerWidth() - elmt.width()

root.get_side_border_padding = get_side_border_padding
