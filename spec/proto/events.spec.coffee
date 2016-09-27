describe "Events", ->
  it "chosen should fire the right events", ->
    tmpl = "
      <select data-placeholder='Choose a Country...'>
        <option value=''></option>
        <option value='United States'>United States</option>
        <option value='United Kingdom'>United Kingdom</option>
        <option value='Afghanistan'>Afghanistan</option>
      </select>
    "

    div = new Element("div")
    document.body.insert(div)

    div.update(tmpl)
    select = div.down("select")
    expect(select).toBeDefined()
    new Chosen(select)

    event_sequence = []
    document.addEventListener 'input', -> event_sequence.push 'input'
    document.addEventListener 'change', -> event_sequence.push 'change'

    container = div.down(".chosen-container")
    container.simulate("mousedown") # open the drop
    expect(container.hasClassName("chosen-container-active")).toBe true

    #select an item
    container.select(".active-result").last().simulate("mouseup")

    expect(event_sequence).toEqual ['input', 'change']
    div.remove()
