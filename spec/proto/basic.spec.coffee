describe "Existential Validation", ->
  it "should add expose a Chosen global", ->
    expect(Chosen).toBeDefined()

describe "Basic Functionality", ->

  beforeEach ->
    tmpl = "
      <select data-placeholder='Choose a Country...' title='Initial Title' class='TestClass'>
        <option value=''></option>
        <option value='United States'>United States</option>
        <option value='United Kingdom'>United Kingdom</option>
        <option value='Afghanistan'>Afghanistan</option>
      </select>
    "

    @div = new Element("div")
    document.body.insert(@div)
    @div.update(tmpl)
    @select = @div.down("select")
    @chosen = new Chosen(@select)
    @container = @div.down(".chosen-container")

  afterEach ->
    @chosen.destroy()
    @div.remove()

  it "should contain all of the necessary elements", ->
    
    div = @div

    expect(@select).toBeDefined()
    
    # very simple check that the necessary elements have been created
    ["container", "container-single", "single", "default"].forEach (clazz)->
      el = div.down(".chosen-#{clazz}")
      expect(el).toBeDefined()

  it "should copy the title attribute from the select to the container", ->
    expect(@container.readAttribute('title')).toBe 'Initial Title'

  it "should be initialized with no value", ->
    # test a few interactions
    expect($F(@select)).toBe ""

  it "should open the dropdown when the container is clicked", ->
    @container.simulate("mousedown") # open the drop
    expect(@container.hasClassName("chosen-container-active")).toBe true

  it "should update the select's value when an option is clicked", ->
    @container.simulate("mousedown") # open the drop
    @container.select(".active-result").last().simulate("mouseup")
    value = $F(@select)
    expect(value).toBe "Afghanistan"

  it "should re-copy the title from the select to the container on update", ->
    @select.writeAttribute('title', 'new title')
    @select.fire("chosen:updated")
    expect(@container.readAttribute('title')).toBe 'new title'

  describe "When inherit selected classes is enabled", ->

    beforeEach ->
      tmpl = "
        <select data-placeholder='Choose a Country...' title='Initial Title' class='TestClass'>
          <option value=''></option>
          <option value='United States'>United States</option>
          <option value='United Kingdom'>United Kingdom</option>
          <option value='Afghanistan'>Afghanistan</option>
        </select>
      "

      @div = new Element("div")
      document.body.insert(@div)
      @div.update(tmpl)
      @select = @div.down("select")
      @chosen = new Chosen(@select, {inherit_select_classes: true})
      @container = @div.down(".chosen-container")

    afterEach ->
      @chosen.destroy()
      @div.remove()

    it "should copy all classes from the select to the container", ->
      expect(@container.hasClassName('TestClass')).toBe true

    it "should re-copy all classes from the select to the container on update", ->
      @select.addClassName('SecondClass')
      @select.fire("chosen:updated")
      # expect(@container.hasClassName('TestClass')).toBe true
      expect(@container.hasClassName('SecondClass')).toBe true

