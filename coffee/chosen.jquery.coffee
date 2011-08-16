###
Chosen source: generate output using 'cake build'
Copyright (c) 2011 by Harvest
###
root = this
$ = jQuery

$.fn.extend({
  chosen: (data, options) ->
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    return this if $.browser is "msie" and ($.browser.version is "6.0" or  $.browser.version is "7.0")
    $(this).each((input_field) ->
      new Chosen(this, data, options) unless ($ this).hasClass "chzn-done"
    )
}) 

class Chosen

  constructor: (elmn) ->
    this.set_default_values()
    
    @form_field = elmn
    @form_field_jq = $ @form_field
    @is_multiple = @form_field.multiple
    @is_rtl = @form_field_jq.hasClass "chzn-rtl"

    @default_text_default = if @form_field.multiple then "Select Some Options" else "Select an Option"

    this.set_up_html()
    this.register_observers()
    @form_field_jq.addClass "chzn-done"

  set_default_values: ->
    
    @click_test_action = (evt) => this.test_active_click(evt)
    @active_field = false
    @mouse_on_container = false
    @results_showing = false
    @result_highlighted = null
    @result_single_selected = null
    @choices = 0

  set_up_html: ->
    @container_id = if @form_field.id.length then @form_field.id.replace(/(:|\.)/g, '_') else this.generate_field_id()
    @container_id += "_chzn"
    
    @f_width = @form_field_jq.width()
    
    @default_text = if @form_field_jq.data 'placeholder' then @form_field_jq.data 'placeholder' else @default_text_default
    
    container_div = ($ "<div />", {
      id: @container_id
      class: "chzn-container #{ if @is_rtl then 'chzn-rtl' else '' }"
      style: 'width: ' + (@f_width) + 'px;' #use parens around @f_width so coffeescript doesn't think + ' px' is a function parameter
    })
    
    if @is_multiple
      container_div.html '<ul class="chzn-choices"><li class="search-field"><input type="text" value="' + @default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chzn-drop" style="left:-9000px;"><ul class="chzn-results"></ul></div>'
    else
      container_div.html '<a href="javascript:void(0)" class="chzn-single"><span>' + @default_text + '</span><div><b></b></div></a><div class="chzn-drop" style="left:-9000px;"><div class="chzn-search"><input type="text" autocomplete="off" /></div><ul class="chzn-results"></ul></div>'

    @form_field_jq.hide().after container_div
    @container = ($ '#' + @container_id)
    @container.addClass( "chzn-container-" + (if @is_multiple then "multi" else "single") )
    @dropdown = @container.find('div.chzn-drop').first()
    
    dd_top = @container.height()
    dd_width = (@f_width - get_side_border_padding(@dropdown))
    
    @dropdown.css({"width": dd_width  + "px", "top": dd_top + "px"})

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
      sf_width = dd_width - get_side_border_padding(@search_container) - get_side_border_padding(@search_field)
      @search_field.css( {"width" : sf_width + "px"} )
    
    this.results_build()
    this.set_tab_index()


  register_observers: ->
    @container.mousedown (evt) => this.container_mousedown(evt)
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
      @selected_item.focus (evt) => this.activate_field(evt)

  container_mousedown: (evt) ->
    if evt and evt.type is "mousedown"
      evt.stopPropagation()
    if not @pending_destroy_click
      if not @active_field
        @search_field.val "" if @is_multiple
        $(document).click @click_test_action
        this.results_show()
      else if not @is_multiple and evt and ($(evt.target) is @selected_item || $(evt.target).parents("a.chzn-single").length)
        evt.preventDefault()
        this.results_toggle()

      this.activate_field()
    else
      @pending_destroy_click = false

  mouse_enter: -> @mouse_on_container = true
  mouse_leave: -> @mouse_on_container = false

  input_focus: (evt) ->
    setTimeout (=> this.container_mousedown()), 50 unless @active_field
  
  input_blur: (evt) ->
    if not @mouse_on_container
      @active_field = false
      setTimeout (=> this.blur_test()), 100

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
    
  results_build: ->
    startTime = new Date()
    @parsing = true
    @results_data = root.SelectParser.select_to_array @form_field

    if @is_multiple and @choices > 0
      @search_choices.find("li.search-choice").remove()
      @choices = 0
    else if not @is_multiple
      @selected_item.find("span").text @default_text

    content = ''
    for data in @results_data
      if data.group
        content += this.result_add_group data
      else if !data.empty
        content += this.result_add_option data
        if data.selected and @is_multiple
          this.choice_build data
        else if data.selected and not @is_multiple
          @selected_item.find("span").text data.text

    this.show_search_field_default()
    this.search_field_scale()
    
    @search_results.html content
    @parsing = false


  result_add_group: (group) ->
    if not group.disabled
      group.dom_id = @container_id + "_g_" + group.array_index
      '<li id="' + group.dom_id + '" class="group-result">' + $("<div />").text(group.label).html() + '</li>'
    else
      ""
  
  result_add_option: (option) ->
    if not option.disabled
      option.dom_id = @container_id + "_o_" + option.array_index
      
      classes = if option.selected and @is_multiple then [] else ["active-result"]
      classes.push "result-selected" if option.selected
      classes.push "group-option" if option.group_array_index?
      
      '<li id="' + option.dom_id + '" class="' + classes.join(' ') + '">' + option.html + '</li>'
    else
      ""

  results_update_field: ->
    this.result_clear_highlight()
    @result_single_selected = null
    this.results_build()

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

  results_toggle: ->
    if @results_showing
      this.results_hide()
    else
      this.results_show()

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
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").first()
    if target.length
      @result_highlight = target
      this.result_select(evt)

  search_results_mouseover: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").first()
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if $(evt.target).hasClass "active-result" or $(evt.target).parents('.active-result').first()


  choices_click: (evt) ->
    evt.preventDefault()
    if( @active_field and not($(evt.target).hasClass "search-choice" or $(evt.target).parents('.search-choice').first) and not @results_showing )
      this.results_show()

  choice_build: (item) ->
    choice_id = @container_id + "_c_" + item.array_index
    @choices += 1
    @search_container.before  '<li class="search-choice" id="' + choice_id + '"><span>' + item.html + '</span><a href="javascript:void(0)" class="search-choice-close" rel="' + item.array_index + '"></a></li>'
    link = $('#' + choice_id).find("a").first()
    link.click (evt) => this.choice_destroy_link_click(evt)

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    @pending_destroy_click = true
    this.choice_destroy $(evt.target)

  choice_destroy: (link) ->
    @choices -= 1
    this.show_search_field_default()

    this.results_hide() if @is_multiple and @choices > 0 and @search_field.val().length < 1

    this.result_deselect (link.attr "rel")
    link.parents('li').first().remove()

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight
      high_id = high.attr "id"
      
      this.result_clear_highlight()

      high.addClass "result-selected"
      
      if @is_multiple
        this.result_deactivate high
      else
        @result_single_selected = high
      
      position = high_id.substr(high_id.lastIndexOf("_") + 1 )
      item = @results_data[position]
      item.selected = true

      @form_field.options[item.options_index].selected = true

      if @is_multiple
        this.choice_build item
      else
        @selected_item.find("span").first().text item.text

      this.results_hide() unless evt.metaKey and @is_multiple

      @search_field.val ""

      @form_field_jq.trigger "change"
      this.search_field_scale()

  result_activate: (el) ->
    el.addClass("active-result").show()

  result_deactivate: (el) ->
    el.removeClass("active-result").hide()

  result_deselect: (pos) ->
    result_data = @results_data[pos]
    result_data.selected = false

    @form_field.options[result_data.options_index].selected = false
    result = $("#" + @container_id + "_o_" + pos)
    result.removeClass("result-selected").addClass("active-result").show()

    this.result_clear_highlight()
    this.winnow_results()

    @form_field_jq.trigger "change"
    this.search_field_scale()

  results_search: (evt) ->
    if @results_showing
      this.winnow_results()
    else
      this.results_show()

  winnow_results: ->
    startTime = new Date()
    this.no_results_clear()
    
    results = 0

    searchText = if @search_field.val() is @default_text then "" else $('<div/>').text($.trim(@search_field.val())).html()
    regex = new RegExp('^' + searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')
    zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')

    for option in @results_data
      if not option.disabled and not option.empty
        if option.group
          $('#' + option.dom_id).hide()
        else if not (@is_multiple and option.selected)
          found = false
          result_id = option.dom_id
          
          if regex.test option.html
            found = true
            results += 1
          else if option.html.indexOf(" ") >= 0 or option.html.indexOf("[") == 0
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

            $("#" + result_id).html text if $("#" + result_id).html != text

            this.result_activate $("#" + result_id)

            $("#" + @results_data[option.group_array_index].dom_id).show() if option.group_array_index?
          else
            this.result_clear_highlight() if @result_highlight and result_id is @result_highlight.attr 'id'
            this.result_deactivate $("#" + result_id)
    
    if results < 1 and searchText.length
      this.no_results searchText
    else
      this.winnow_results_set_highlight()

  winnow_results_clear: ->
    @search_field.val ""
    lis = @search_results.find("li")

    for li in lis
      li = $(li)
      if li.hasClass "group-result"
        li.show()
      else if not @is_multiple or not li.hasClass "result-selected"
        this.result_activate li

  winnow_results_set_highlight: ->
    if not @result_highlight

      selected_results = if not @is_multiple then @search_results.find(".result-selected") else []
      do_high = if selected_results.length then selected_results.first() else @search_results.find(".active-result").first()

      this.result_do_highlight do_high if do_high?
  
  no_results: (terms) ->
    no_results_html = $('<li class="no-results">No results match "<span></span>"</li>')
    no_results_html.find("span").first().html(terms)

    @search_results.append no_results_html
  
  no_results_clear: ->
    @search_results.find(".no-results").remove()

  keydown_arrow: ->
    if not @result_highlight
      first_active = @search_results.find("li.active-result").first()
      this.result_do_highlight $(first_active) if first_active
    else if @results_showing
      next_sib = @result_highlight.nextAll("li.active-result").first()
      this.result_do_highlight next_sib if next_sib
    this.results_show() if not @results_showing

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      prev_sibs = @result_highlight.prevAll("li.active-result")
      
      if prev_sibs.length
        this.result_do_highlight prev_sibs.first()
      else
        this.results_hide() if @choices > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.find("a").first()
      this.clear_backstroke()
    else
      @pending_backstroke = @search_container.siblings("li.search-choice").last()
      @pending_backstroke.addClass "search-choice-focus"

  clear_backstroke: ->
    @pending_backstroke.removeClass "search-choice-focus" if @pending_backstroke
    @pending_backstroke = null

  keyup_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()

    switch stroke
      when 8
        if @is_multiple and @backstroke_length < 1 and @choices > 0
          this.keydown_backstroke()
        else if not @pending_backstroke
          this.result_clear_highlight()
          this.results_search()
      when 13
        evt.preventDefault()
        this.result_select(evt) if this.results_showing
      when 27
        this.results_hide() if @results_showing
      when 9, 38, 40, 16, 91, 17
        # don't do anything on these keys
      else this.results_search()


  keydown_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()
    
    this.clear_backstroke() if stroke != 8 and this.pending_backstroke
    
    switch stroke
      when 8
        @backstroke_length = this.search_field.val().length
        break
      when 9
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
      
      div = $('<div />', { 'style' : style_block })
      div.text @search_field.val()
      $('body').append div

      w = div.width() + 25
      div.remove()

      if( w > @f_width-10 )
        w = @f_width - 10

      @search_field.css({'width': w + 'px'})

      dd_top = @container.height()
      @dropdown.css({"top":  dd_top + "px"})
  
  generate_field_id: ->
    new_id = this.generate_random_id()
    @form_field.id = new_id
    new_id
  
  generate_random_id: ->
    string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char()
    while $("#" + string).length > 0
      string += this.generate_random_char()
    string
    
  generate_random_char: ->
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ";
    rand = Math.floor(Math.random() * chars.length)
    newchar = chars.substring rand, rand+1

get_side_border_padding = (elmt) ->
  side_border_padding = elmt.outerWidth() - elmt.width()

root.get_side_border_padding = get_side_border_padding
