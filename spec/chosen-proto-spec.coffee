describe "Chosen", ->

  context = {}
  select = null
  container = null
  option = new Template('<option value="#{value}">#{text}</option>')

  beforeEach ->
    container = new Element('div')
    select = new Element('select')

    countries.forEach (value) ->
      select.insert( option.evaluate({value: value, text: value}) )
    container.insert(select)
    context.chosen = new Chosen(select)

  sharedBehavior(context)