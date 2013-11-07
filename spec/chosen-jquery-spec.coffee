describe "Chosen", ->

  context = {}
  select = null
  container = null

  beforeEach ->
    container = $('<div/>')
    select = $('<select/>')
    countries.forEach (value) ->
      select.append($('<option/>').val(value).text(value))
    container.append(select)
    context.chosen = select.chosen().data('chosen')

  sharedBehavior(context)