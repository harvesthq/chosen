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
    simulant.fire(container, "mousedown") # open the drop
    expect(container.hasClassName("chosen-container-active")).toBe true

    #select an item
    result = container.select(".active-result").last()
    simulant.fire(result, "mouseup")

    expect($F(select)).toBe "Afghanistan"
    div.remove()

  describe "data-placeholder", ->

    it "should render", ->
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

      placeholder = div.down(".chosen-single > span")
      expect(placeholder.innerText).toBe("Choose a Country...")

    it "should render with special characters", ->
      tmpl = "
        <select data-placeholder='&lt;None&gt;'>
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

      placeholder = div.down(".chosen-single > span")
      expect(placeholder.innerText).toBe("<None>")

  describe "disabled fieldset", ->

    it "should render as disabled", ->
      tmpl = "
        <fieldset disabled>
          <select data-placeholder='Choose a Country...'>
            <option value=''></option>
            <option value='United States'>United States</option>
            <option value='United Kingdom'>United Kingdom</option>
            <option value='Afghanistan'>Afghanistan</option>
          </select>
        </fieldset>
      "
      div = new Element("div")
      document.body.insert(div)
      div.update(tmpl)
      select = div.down("select")
      expect(select).toBeDefined()
      new Chosen(select)

      container = div.down(".chosen-container")
      expect(container.hasClassName("chosen-disabled")).toBe true
      
  it "it should not render hidden options", ->
    tmpl = "
      <select data-placeholder='Choose a Country...'>
        <option value='' hidden>Choose a Country</option>
        <option value='United States'>United States</option>
      </select>
    "
    div = new Element("div")
    document.body.insert(div)
    div.update(tmpl)
    select = div.down("select")
    expect(select).toBeDefined()
    new Chosen(select)
    container = div.down(".chosen-container")
    simulant.fire(container, "mousedown") # open the drop
    expect(container.select(".active-result").length).toBe 1

  it "it should not render hidden optgroups", ->
    tmpl = "
      <select>
        <optgroup label='Not shown' hidden>
          <option value='Item1'>Item1</option>
        </optgroup>
        <optgroup label='Shown'>
          <option value='Item2'>Item2</option>
        </optgroup>
      </select>
    "
    div = new Element("div")
    document.body.insert(div)
    div.update(tmpl)
    select = div.down("select")
    expect(select).toBeDefined()
    new Chosen(select)
    container = div.down(".chosen-container")
    simulant.fire(container, "mousedown") # open the drop
    expect(container.select(".group-result").length).toBe 1
    expect(container.select(".active-result").length).toBe 1
