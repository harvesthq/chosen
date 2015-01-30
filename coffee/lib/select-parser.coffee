class SelectParser

  constructor: ->
    @options_index = 0
    @parsed = []

  add_node: (child) ->
    if child.nodeName.toUpperCase() is "OPTGROUP"
      this.add_group child
    else
      this.add_option child

  add_group: (group) ->
    group_position = @parsed.length
    @parsed.push
      array_index: group_position
      group: true
      label: this.escapeExpression(group.label)
      title: group.title if group.title
      children: 0
      disabled: group.disabled,
      classes: group.className
    this.add_option( option, group_position, group.disabled ) for option in group.childNodes

  add_option: (option, group_position, group_disabled) ->
    if option.nodeName.toUpperCase() is "OPTION"
      if option.text != ""
        if group_position?
          @parsed[group_position].children += 1
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          value: option.value
          text: option.text
          html: option.innerHTML
          title: option.title if option.title
          selected: option.selected
          disabled: if group_disabled is true then group_disabled else option.disabled
          group_array_index: group_position
          group_label: if group_position? then @parsed[group_position].label else null
          classes: option.className
          style: option.style.cssText
      else
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          empty: true
      @options_index += 1

  escapeExpression: (text) ->
    if not text? or text is false
      return ""
    unless /[\&\<\>\"\'\`]/.test(text)
      return text
    map =
      "<": "&lt;"
      ">": "&gt;"
      '"': "&quot;"
      "'": "&#x27;"
      "`": "&#x60;"
    unsafe_chars = /&(?!\w+;)|[\<\>\"\'\`]/g
    text.replace unsafe_chars, (chr) ->
      map[chr] || "&amp;"

SelectParser.select_to_array = (select) ->
  parser = new SelectParser()
  parser.add_node( child ) for child in select.childNodes
  parser.parsed
