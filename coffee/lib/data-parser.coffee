class DataParser

  constructor: ->
    @options_index = 0
    @parsed = []

  add_node: (child) ->
    if child["options"]?
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
    this.add_option( option, group_position, group.disabled ) for option in group["options"]

  add_option: (option, group_position, group_disabled) ->
    if !option["options"]?
      if option.text != ""
        if group_position?
          @parsed[group_position].children += 1
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          value: option.value
          text: option.text
          html: option.text
          selected: if option.selected? then option.selected else null
          disabled: if group_disabled is true then group_disabled else option.disabled
          group_array_index: group_position
          classes: option.className
          style: ""
      else
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          empty: true
      @options_index += 1

DataParser.data_to_array = (data) ->
  parser = new DataParser()
  parser.add_node( child ) for child in data
  parser.parsed

this.DataParser = DataParser
