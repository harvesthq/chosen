describe "Basic setup", ->
  it "should add chosen to jQuery object", ->
    expect(jQuery.fn.chosen).toBeDefined()

  it "should create very basic chosen", ->
    tmpl = "
      <select data-placeholder='Choose a Country...'>
        <option value=''></option>
        <option value='United States'>United States</option>
        <option value='United Kingdom'>United Kingdom</option>
        <option value='Afghanistan'>Afghanistan</option>
      </select>
    "
    div = $("<div>").html(tmpl)
    select = div.find("select")
    expect(select.size()).toBe(1)
    select.chosen()
    # very simple check that the necessary elements have been created
    ["container", "container-single", "single", "default"].forEach (clazz)->
      el = div.find(".chosen-#{clazz}")
      expect(el.size()).toBe(1)

    # test a few interactions
    expect(select.val()).toBe ""

    container = div.find(".chosen-container")
    container.trigger("mousedown") # open the drop
    expect(container.hasClass("chosen-container-active")).toBe true
    #select an item
    container.find(".active-result").last().trigger("mouseup")

    expect(select.val()).toBe "Afghanistan"

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
      div = $("<div>").html(tmpl)
      select = div.find("select")
      expect(select.size()).toBe(1)
      select.chosen()
      placeholder = div.find(".chosen-single > span")
      expect(placeholder.text()).toBe("Choose a Country...")

    it "should render with special characters", ->
      tmpl = "
        <select data-placeholder='&lt;None&gt;'>
          <option value=''></option>
          <option value='United States'>United States</option>
          <option value='United Kingdom'>United Kingdom</option>
          <option value='Afghanistan'>Afghanistan</option>
        </select>
      "
      div = $("<div>").html(tmpl)
      select = div.find("select")
      expect(select.size()).toBe(1)
      select.chosen()
      placeholder = div.find(".chosen-single > span")
      expect(placeholder.text()).toBe("<None>")

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
      div = $("<div>").html(tmpl)
      select = div.find("select")
      expect(select.size()).toBe(1)
      select.chosen()

      container = div.find(".chosen-container")
      expect(container.hasClass("chosen-disabled")).toBe true
