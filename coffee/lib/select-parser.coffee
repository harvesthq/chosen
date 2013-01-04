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
      label: group.label
      children: 0
      disabled: group.disabled
    this.add_option( option, group_position, group.disabled ) for option in group.childNodes

  get_template_data: (option) ->
    template_data = {}

    for k, v of option.attributes
      if typeof(v.nodeName) == "string"
        attribute_name = v.nodeName.split("-")

        if attribute_name[0] == "data" and attribute_name = attribute_name[1..]
          for word, i in attribute_name
            attribute_name[i] = word.charAt(0).toUpperCase() + word.slice(1) if i != 0
            
          template_data[attribute_name.join("")] = v.nodeValue 

    template_data

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
          selected: option.selected
          disabled: if group_disabled is true then group_disabled else option.disabled
          group_array_index: group_position
          classes: option.className
          style: option.style.cssText
          template_data: @get_template_data(option)
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

this.SelectParser = SelectParser
