describe "Searching", ->
  it "should not match the actual text of HTML entities", ->
    tmpl = "
      <select data-placeholder='Choose an HTML Entity...'>
        <option value=''></option>
        <option value='This & That'>This &amp; That</option>
        <option value='This < That'>This &lt; That</option>
      </select>
    "

    div = new Element('div')
    document.body.insert(div)
    div.update(tmpl)
    select = div.down('select')
    new Chosen(select, {search_contains: true})

    container = div.down('.chosen-container')
    simulant.fire(container, 'mousedown') # open the drop

    # Both options should be active
    results = div.select('.active-result')
    expect(results.length).toBe(2)

    # Search for the html entity by name
    search_field = div.down(".chosen-search input")
    search_field.value = "mp"
    simulant.fire(search_field, 'keyup')

    results = div.select(".active-result")
    expect(results.length).toBe(0)

  it "renders options correctly when they contain characters that require HTML encoding", ->
    div = new Element("div")
    div.update("""
      <select>
        <option value="A &amp; B">A &amp; B</option>
      </select>
    """)

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".active-result").length).toBe(1)
    expect(div.down(".active-result").innerHTML).toBe("A &amp; B")

    search_field = div.down(".chosen-search-input")
    search_field.value = "A"
    simulant.fire(search_field, "keyup")

    expect(div.select(".active-result").length).toBe(1)
    expect(div.down(".active-result").innerHTML).toBe("<em>A</em> &amp; B")

  it "renders optgroups correctly when they contain characters that require HTML encoding", ->
    div = new Element("div")
    div.update("""
      <select>
        <optgroup label="A &amp; B">
          <option value="Item">Item</option>
        </optgroup>
      </select>
    """)

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".group-result").length).toBe(1)
    expect(div.down(".group-result").innerHTML).toBe("A &amp; B")

    search_field = div.down(".chosen-search-input")
    search_field.value = "A"
    simulant.fire(search_field, "keyup")

    expect(div.select(".group-result").length).toBe(1)
    expect(div.down(".group-result").innerHTML).toBe("<em>A</em> &amp; B")
