describe "Existential Validation", ->
  it "should add chosen to jQuery object", ->
    expect(jQuery.fn.chosen).toBeDefined()

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
    @div = $("<div>").html(tmpl)
    @select = @div.find('select')
    @select.chosen()
    @container = @div.find(".chosen-container")

  afterEach ->
    @select.chosen('destroy')
    @div.remove()

  it "should contain all of the necessary elements", ->

    div = @div

    # very simple check that the necessary elements have been created
    ["container", "container-single", "single", "default"].forEach (clazz)->
      el = div.find(".chosen-#{clazz}")
      expect(el.size()).toBe(1)

  it "should copy the title attribute from the select to the container", ->
    expect(@container.attr('title')).toBe 'Initial Title'

  it "should be initialized with no value", ->
    # test a few interactions
    expect(@select.val()).toBe ""

  it "should open the dropdown when the container is clicked", ->
    @container.trigger("mousedown") # open the drop
    expect(@container.hasClass("chosen-container-active")).toBe true

  it "should update the select's value when an option is clicked", ->
    @container.trigger("mousedown") # open the drop
    #select an item
    @container.find(".active-result").last().trigger("mouseup")

    expect(@select.val()).toBe "Afghanistan"

  it "should re-copy the title from the select to the container on update", ->
    @select.attr('title', 'new title')
    @select.trigger("chosen:updated")
    expect(@container.attr('title')).toBe 'new title'

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
    @div = $("<div>").html(tmpl)
    @select = @div.find('select')
    @select.chosen({inherit_select_classes: true})
    @container = @div.find(".chosen-container")

  afterEach ->
    @select.chosen('destroy')
    @div.remove()

  it "should copy all classes from the select to the container", ->
    expect(@container.hasClass('TestClass')).toBe true

  it "should re-copy all classes from the select to the container on update", ->
    @select.addClass('SecondClass')
    @select.trigger("chosen:updated")
    expect(@container.hasClass('TestClass')).toBe true
    expect(@container.hasClass('SecondClass')).toBe true




