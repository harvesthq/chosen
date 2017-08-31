describe "Searching", ->
  it "should not match the actual text of HTML entities", ->
    tmpl = "
      <select data-placeholder='Choose an HTML Entity...'>
        <option value=''></option>
        <option value='This & That'>This &amp; That</option>
        <option value='This < That'>This &lt; That</option>
      </select>
    "

    div = $("<div>").html(tmpl)
    select = div.find("select")
    select.chosen({search_contains: true})

    container = div.find(".chosen-container")
    container.trigger("mousedown") # open the drop

    # Both options should be active
    results = div.find(".active-result")
    expect(results.length).toBe(2)

    # Search for the html entity by name
    search_field = div.find(".chosen-search input").first()
    search_field.val("mp")
    search_field.trigger("keyup")

    results = div.find(".active-result")
    expect(results.length).toBe(0)

  it "renders options correctly when they contain characters that require HTML encoding", ->
    div = $("<div>").html("""
      <select>
        <option value="A &amp; B">A &amp; B</option>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".active-result").length).toBe(1)
    expect(div.find(".active-result").first().html()).toBe("A &amp; B")

    search_field = div.find(".chosen-search-input").first()
    search_field.val("A")
    search_field.trigger("keyup")

    expect(div.find(".active-result").length).toBe(1)
    expect(div.find(".active-result").first().html()).toBe("<em>A</em> &amp; B")

  it "renders optgroups correctly when they contain characters that require HTML encoding", ->
    div = $("<div>").html("""
      <select>
        <optgroup label="A &amp; B">
          <option value="Item">Item</option>
        </optgroup>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".group-result").length).toBe(1)
    expect(div.find(".group-result").first().html()).toBe("A &amp; B")

    search_field = div.find(".chosen-search-input").first()
    search_field.val("A")
    search_field.trigger("keyup")

    expect(div.find(".group-result").length).toBe(1)
    expect(div.find(".group-result").first().html()).toBe("<em>A</em> &amp; B")
