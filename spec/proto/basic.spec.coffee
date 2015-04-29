describe "Basic setup", ->
  it "should add expose a Chosen global", ->
    expect(Chosen).toBeDefined()

  it "should create very basic chosen", ->
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
    # very simple check that the necessary elements have been created
    ["container", "container-single", "single", "default"].forEach (clazz)->
      el = div.down(".chosen-#{clazz}")
      expect(el).toBeDefined()

    # test a few interactions
    expect($F(select)).toBe ""

    container = div.down(".chosen-container")
    container.simulate("mousedown") # open the drop
    expect(container.hasClassName("chosen-container-active")).toBe true

    #select an item
    container.select(".active-result").last().simulate("mouseup")

    expect($F(select)).toBe "Afghanistan"
    div.remove()
