###
Chosen, a Select Box Enhancer for jQuery and Protoype
by Patrick Filler for Harvest, http://getharvest.com

Available for use under the MIT License, http://en.wikipedia.org/wiki/MIT_License

Copyright (c) 2011 by Harvest
###

root = exports ? this

class Chosen

  constructor: (elmn) ->
    this.set_default_values()
    
    @form_field = elmn
    @is_multiple = @form_field.multiple

    @default_text_default = if @form_field.multiple then "Select Some Options" else "Select an Option"

    this.set_up_html()
    this.register_observers()


  set_default_values: ->
    
    @click_test_action = (evt) => this.test_active_click(evt)
    @active_field = false
    @mouse_on_container = false
    @results_showing = false
    @result_highlighted = null
    @result_single_selected = null
    @choices = 0

    # HTML Templates
    @single_temp = new Template('<a href="javascript:void(0)" class="chzn-single"><span>#{default}</span><div><b></b></div></a><div class="chzn-drop" style="left:-9000px;"><div class="chzn-search"><input type="text" /></div><ul class="chzn-results"></ul></div>')
    @multi_temp = new Template('<ul class="chzn-choices"><li class="search-field"><input type="text" value="#{default}" class="default" style="width:25px;" /></li></ul><div class="chzn-drop" style="left:-9000px;"><ul class="chzn-results"></ul></div>')
    @choice_temp = new Template('<li class="search-choice" id="#{id}"><span>#{choice}</span><a href="javascript:void(0)" class="search-choice-close" rel="#{position}"></a></li>')
    @no_results_temp = new Template('<li class="no-results">No results match "<span>#{terms}</span>"</li>')


  set_up_html: ->
    @container_id = @form_field.identify().replace('.', '_') + "_chzn"
    
    @f_width = if @form_field.getStyle("width") then parseInt @form_field.getStyle("width"), 10 else @form_field.getWidth()
    
    container_props =
      'id': @container_id
      'class': 'chzn-container'
      'style': 'width: ' + (@f_width) + 'px' #use parens around @f_width so coffeescript doesn't think + ' px' is a function parameter
    
    @default_text = if @form_field.readAttribute 'title' then @form_field.readAttribute 'title' else @default_text_default
    
    base_template = if @is_multiple then new Element('div', container_props).update( @multi_temp.evaluate({ "default": @default_text}) ) else new Element('div', container_props).update( @single_temp.evaluate({ "default":@default_text }) )

    @form_field.hide().insert({ after: base_template })
    @container = $(@container_id)
    @container.addClassName( "chzn-container-" + (if @is_multiple then "multi" else "single") )
    @dropdown = @container.down('div.chzn-drop')
    
    dd_top = @container.getHeight()
    dd_width = (@f_width - get_side_border_padding(@dropdown))
    
    @dropdown.setStyle({"width": dd_width  + "px", "top": dd_top + "px"})

    @search_field = @container.down('input')
    @search_results = @container.down('ul.chzn-results')
    this.search_field_scale()

    @search_no_results = @container.down('li.no-results')
    
    if @is_multiple
      @search_choices = @container.down('ul.chzn-choices')
      @search_container = @container.down('li.search-field')
    else
      @search_container = @container.down('div.chzn-search')
      @selected_item = @container.down('.chzn-single')
      sf_width = dd_width - get_side_border_padding(@search_container) - get_side_border_padding(@search_field)
      @search_field.setStyle( {"width" : sf_width + "px"} )
    
    this.results_build()
    this.set_tab_index()


  register_observers: ->
    @container.observe "click", (evt) => this.container_click(evt)
    @container.observe "mouseenter", (evt) => this.mouse_enter(evt)
    @container.observe "mouseleave", (evt) => this.mouse_leave(evt)
    
    @search_results.observe "click", (evt) => this.search_results_click(evt)
    @search_results.observe "mouseover", (evt) => this.search_results_mouseover(evt)
    @search_results.observe "mouseout", (evt) => this.search_results_mouseout(evt)
    
    @form_field.observe "liszt:updated", (evt) => this.results_update_field(evt)

    @search_field.observe "blur", (evt) => this.input_blur(evt)
    @search_field.observe "keyup", (evt) => this.keyup_checker(evt)
    @search_field.observe "keydown", (evt) => this.keydown_checker(evt)

    if @is_multiple
      @search_choices.observe "click", (evt) => this.choices_click(evt)
      @search_field.observe "focus", (evt) => this.input_focus(evt)
    else
      @selected_item.observe "focus", (evt) => this.activate_field(evt)


  container_click: (evt) ->
    if evt and evt.type is "click"
      evt.stop()
    if not @pending_destroy_click
      if not @active_field
        @search_field.clear() if @is_multiple
        document.observe "click", @click_test_action
        this.results_show()
      else if not @is_multiple and evt and (evt.target is @selected_item || evt.target.up("a.chzn-single"))
        this.results_toggle()

      this.activate_field()
    else
      @pending_destroy_click = false

  mouse_enter: -> @mouse_on_container = true
  mouse_leave: -> @mouse_on_container = false

  input_focus: (evt) ->
    setTimeout this.container_click.bind(this), 50 unless @active_field
  
  input_blur: (evt) ->
    if not @mouse_on_container
      @active_field = false
      setTimeout this.blur_test.bind(this), 100

  blur_test: (evt) ->
    this.close_field() if not @active_field and @container.hasClassName("chzn-container-active")

  close_field: ->
    document.stopObserving "click", @click_test_action
    
    if not @is_multiple
      @selected_item.tabIndex = @search_field.tabIndex
      @search_field.tabIndex = -1
    
    @active_field = false
    this.results_hide()

    @container.removeClassName "chzn-container-active"
    this.winnow_results_clear()
    this.clear_backstroke()

    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
    if not @is_multiple and not @active_field
      @search_field.tabIndex = @selected_item.tabIndex
      @selected_item.tabIndex = -1

    @container.addClassName "chzn-container-active"
    @active_field = true

    @search_field.value = @search_field.value
    @search_field.focus()


  test_active_click: (evt) ->
    if evt.target.up('#' + @container_id)
      @active_field = true
    else
      this.close_field()

  results_build: ->
    startTime = new Date()
    @parsing = true
    @results_data = SelectParser.select_to_array @form_field

    if @is_multiple and @choices > 0
      @search_choices.select("li.search-choice").invoke("remove")
      @choices = 0
    else if not @is_multiple
      @selected_item.down("span").update(@default_text)

    content = ''
    for data in @results_data
      if data.group
        content += this.result_add_group data
      else if !data.empty
        content += this.result_add_option data
        if data.selected and @is_multiple
          this.choice_build data
        else if data.selected and not @is_multiple
          @selected_item.down("span").update( data.html )

    this.show_search_field_default()
    this.search_field_scale()
    
    @search_results.update content
    @parsing = false


  result_add_group: (group) ->
    if not group.disabled
      group.dom_id = @container_id + "_g_" + group.array_index
      '<li id="' + group.dom_id + '" class="group-result">' + group.label.escapeHTML() + '</li>'
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

  results_toggle: ->
    if @results_showing
      this.results_hide()
    else
      this.results_show()

  results_show: ->
    if not @is_multiple
      @selected_item.addClassName('chzn-single-with-drop')
      if @result_single_selected
        this.result_do_highlight( @result_single_selected )

    dd_top = if @is_multiple then @container.getHeight() else (@container.getHeight() - 1)
    @dropdown.setStyle {"top":  dd_top + "px", "left":0}
    @results_showing = true

    @search_field.focus()
    @search_field.value = @search_field.value

    this.winnow_results()

  results_hide: ->
    @selected_item.removeClassName('chzn-single-with-drop') unless @is_multiple
    this.result_clear_highlight()
    @dropdown.setStyle({"left":"-9000px"})
    @results_showing = false


  set_tab_index: (el) ->
    if @form_field.tabIndex
      ti = @form_field.tabIndex
      @form_field.tabIndex = -1

      if @is_multiple
        @search_field.tabIndex = ti
      else
        @selected_item.tabIndex = ti
        @search_field.tabIndex = -1

  show_search_field_default: ->
    if @is_multiple and @choices < 1 and not @active_field
      @search_field.value = @default_text
      @search_field.addClassName "default"
    else
      @search_field.value = ""
      @search_field.removeClassName "default"

  search_results_click: (evt) ->
    target = if evt.target.hasClassName("active-result") then evt.target else evt.target.up(".active-result")
    if target
      @result_highlight = target
      this.result_select()

  search_results_mouseover: (evt) ->
    target = if evt.target.hasClassName("active-result") then evt.target else evt.target.up(".active-result")
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if evt.target.hasClassName('active-result') or evt.target.up('.active-result')


  choices_click: (evt) ->
    evt.preventDefault()
    if( @active_field and not(evt.target.hasClassName('search-choice') or evt.target.up('.search-choice')) and not @results_showing )
      this.results_show()

  choice_build: (item) ->
    choice_id = @container_id + "_c_" + item.array_index
    @choices += 1
    @search_container.insert
      before: @choice_temp.evaluate
        id:       choice_id
        choice:   item.html
        position: item.array_index
    link = $(choice_id).down('a')
    link.observe "click", (evt) => this.choice_destroy_link_click(evt)

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    @pending_destroy_click = true
    this.choice_destroy evt.target

  choice_destroy: (link) ->
    @choices -= 1
    this.show_search_field_default()

    this.results_hide() if @is_multiple and @choices > 0 and @search_field.value.length < 1

    this.result_deselect link.readAttribute("rel")
    link.up('li').remove()

  result_select: ->
    if @result_highlight
      high = @result_highlight
      this.result_clear_highlight()

      high.addClassName("result-selected")
      
      if @is_multiple
        this.result_deactivate high
      else
        @result_single_selected = high
        
      position = high.id.substr(high.id.lastIndexOf("_") + 1 )
      item = @results_data[position]
      item.selected = true

      @form_field.options[item.options_index].selected = true

      if @is_multiple
        this.choice_build item
      else
        @selected_item.down("span").update(item.html)

      this.results_hide()
      @search_field.value = ""

      @form_field.simulate("change") if typeof Event.simulate is 'function'
      this.search_field_scale()

  result_activate: (el) ->
    el.addClassName("active-result").show()

  result_deactivate: (el) ->
    el.removeClassName("active-result").hide()

  result_deselect: (pos) ->
    result_data = @results_data[pos]
    result_data.selected = false

    @form_field.options[result_data.options_index].selected = false
    result = $(@container_id + "_o_" + pos)
    result.removeClassName("result-selected").addClassName("active-result").show()

    this.result_clear_highlight()
    this.winnow_results()

    @form_field.simulate("change") if typeof Event.simulate is 'function'
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

    searchText = if @search_field.value is @default_text then "" else @search_field.value.strip().escapeHTML()
    regex = new RegExp('^' + searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')
    zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i')

    for option in @results_data
      if not option.disabled and not option.empty
        if option.group
          $(option.dom_id).hide()
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

            $(result_id).update text if $(result_id).innerHTML != text

            this.result_activate $(result_id)

            $(@results_data[option.group_array_index].dom_id).show() if option.group_array_index?
          else
            this.result_clear_highlight() if $(result_id) is @result_highlight
            this.result_deactivate $(result_id)

    if results < 1 and searchText.length
      this.no_results(searchText)
    else
      this.winnow_results_set_highlight()

  winnow_results_clear: ->
    @search_field.clear()
    lis = @search_results.select("li")

    for li in lis
      if li.hasClassName("group-result")
        li.show()
      else if not @is_multiple or not li.hasClassName("result-selected")
        this.result_activate li

  winnow_results_set_highlight: ->
    if not @result_highlight
      do_high = @search_results.down(".active-result")
      if(do_high)
        this.result_do_highlight do_high
  
  no_results: (terms) ->
    @search_results.insert @no_results_temp.evaluate( terms: terms )
  
  no_results_clear: ->
    nr = null
    nr.remove() while nr = @search_results.down(".no-results")


  keydown_arrow: ->
    actives = @search_results.select("li.active-result")
    if actives.length
      if not @result_highlight
        this.result_do_highlight actives.first()
      else if @results_showing
        sibs = @result_highlight.nextSiblings()
        nexts = sibs.intersect(actives)
        this.result_do_highlight nexts.first() if nexts.length
      this.results_show() if not @results_showing

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
        this.results_hide() if @choices > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.down("a")
      this.clear_backstroke()
    else
      @pending_backstroke = @search_container.siblings("li.search-choice").last()
      @pending_backstroke.addClassName("search-choice-focus")

  clear_backstroke: ->
    @pending_backstroke.removeClassName("search-choice-focus") if @pending_backstroke
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
        this.result_select() if this.results_showing
      when 27
        this.results_hide() if @results_showing
      when 9, 38, 40, 16
        # don't do anything on these keys
      else this.results_search()


  keydown_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()

    this.clear_backstroke() if stroke != 8 and this.pending_backstroke
    
    switch stroke
      when 8
        @backstroke_length = this.search_field.value.length
      when 9
        @mouse_on_container = false
      when 13
        evt.preventDefault()
      when 38
        evt.preventDefault()
        this.keyup_arrow()
      when 40
        this.keydown_arrow()


  search_field_scale: ->
    if @is_multiple
      h = 0
      w = 0

      style_block = "position:absolute; left: -1000px; top: -1000px; display:none;"
      styles = ['font-size','font-style', 'font-weight', 'font-family','line-height', 'text-transform', 'letter-spacing']
      
      for style in styles
        style_block += style + ":" + @search_field.getStyle(style) + ";"
      
      div = new Element('div', { 'style' : style_block }).update(@search_field.value.escapeHTML())
      document.body.appendChild(div)

      w = Element.measure(div, 'width') + 25
      div.remove()

      if( w > @f_width-10 )
        w = @f_width - 10

      @search_field.setStyle({'width': w + 'px'})

      dd_top = @container.getHeight()
      @dropdown.setStyle({"top":  dd_top + "px"})

root.Chosen = Chosen

document.observe 'dom:loaded', (evt) ->
  selects = $$(".chzn-select")
  new Chosen select for select in selects

get_side_border_padding = (elmt) ->
  layout = new Element.Layout(elmt)
  side_border_padding = layout.get("border-left") + layout.get("border-right") + layout.get("padding-left") + layout.get("padding-right")

root.get_side_border_padding = get_side_border_padding

root = exports ? this

class SelectParser
  
  constructor: ->
    @options_index = 0
    @parsed = []

  add_node: (child) ->
    if child.nodeName is "OPTGROUP"
      this.add_group child
    else
      this.add_option child

  add_group: (group) ->
    group_position = @parsed.length
    @parsed.push
      array_index: group_position
      group: true
      label: group.label
      children: 0
      disabled: group.disabled
    this.add_option( option, group_position, group.disabled ) for option in group.childNodes

  add_option: (option, group_position, group_disabled) ->
    if option.nodeName is "OPTION"
      if option.text != ""
        if group_position?
          @parsed[group_position].children += 1
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          value: option.value
          text: option.text
          html: option.innerHTML
          selected: option.selected
          disabled: if group_disabled is true then group_disabled else option.disabled
          group_array_index: group_position
      else
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          empty: true
      @options_index += 1

SelectParser.select_to_array = (select) ->
  parser = new SelectParser()
  parser.add_node( child ) for child in select.childNodes
  parser.parsed
  
root.SelectParser = SelectParser
