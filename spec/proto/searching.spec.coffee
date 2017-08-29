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

  it "matches in non-ascii languages like Chinese when selecting a single item", ->
    div = new Element("div")
    div.update("""
      <select>
        <option value="一">一</option>
        <option value="二">二</option>
        <option value="三">三</option>
        <option value="四">四</option>
        <option value="五">五</option>
        <option value="六">六</option>
        <option value="七">七</option>
        <option value="八">八</option>
        <option value="九">九</option>
        <option value="十">十</option>
        <option value="十一">十一</option>
        <option value="十二">十二</option>
      </select>
    """)

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".active-result").length).toBe(12)

    search_field = div.down(".chosen-search-input")
    search_field.value = "一"
    simulant.fire(search_field, "keyup")

    expect(div.select(".active-result").length).toBe(1)
    expect(div.select(".active-result")[0].innerHTML).toBe("<em>一</em>")

  it "matches in non-ascii languages like Chinese when selecting a single item with search_contains", ->
    div = new Element("div")
    div.update("""
      <select>
        <option value="一">一</option>
        <option value="二">二</option>
        <option value="三">三</option>
        <option value="四">四</option>
        <option value="五">五</option>
        <option value="六">六</option>
        <option value="七">七</option>
        <option value="八">八</option>
        <option value="九">九</option>
        <option value="十">十</option>
        <option value="十一">十一</option>
        <option value="十二">十二</option>
      </select>
    """)

    new Chosen(div.down("select"), {search_contains: true})
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".active-result").length).toBe(12)

    search_field = div.down(".chosen-search-input")
    search_field.value = "一"
    simulant.fire(search_field, "keyup")

    expect(div.select(".active-result").length).toBe(2)
    expect(div.select(".active-result")[0].innerHTML).toBe("<em>一</em>")
    expect(div.select(".active-result")[1].innerHTML).toBe("十<em>一</em>")

  it "matches in non-ascii languages like Chinese when selecting multiple items", ->
    div = new Element("div")
    div.update("""
      <select multiple>
        <option value="一">一</option>
        <option value="二">二</option>
        <option value="三">三</option>
        <option value="四">四</option>
        <option value="五">五</option>
        <option value="六">六</option>
        <option value="七">七</option>
        <option value="八">八</option>
        <option value="九">九</option>
        <option value="十">十</option>
        <option value="十一">十一</option>
        <option value="十二">十二</option>
      </select>
    """)

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".active-result").length).toBe(12)

    search_field = div.down(".chosen-search-input")
    search_field.value = "一"
    simulant.fire(search_field, "keyup")

    expect(div.select(".active-result").length).toBe(1)
    expect(div.select(".active-result")[0].innerHTML).toBe("<em>一</em>")

  it "matches in non-ascii languages like Chinese when selecting multiple items with search_contains", ->
    div = new Element("div")
    div.update("""
      <select multiple>
        <option value="一">一</option>
        <option value="二">二</option>
        <option value="三">三</option>
        <option value="四">四</option>
        <option value="五">五</option>
        <option value="六">六</option>
        <option value="七">七</option>
        <option value="八">八</option>
        <option value="九">九</option>
        <option value="十">十</option>
        <option value="十一">十一</option>
        <option value="十二">十二</option>
      </select>
    """)

    new Chosen(div.down("select"), {search_contains: true})
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".active-result").length).toBe(12)

    search_field = div.down(".chosen-search-input")
    search_field.value = "一"
    simulant.fire(search_field, "keyup")

    expect(div.select(".active-result").length).toBe(2)
    expect(div.select(".active-result")[0].innerHTML).toBe("<em>一</em>")
    expect(div.select(".active-result")[1].innerHTML).toBe("十<em>一</em>")

  it "highlights results correctly when multiple words are present", ->
    div = new Element("div")
    div.update("""
      <select>
        <option value="oh hello">oh hello</option>
      </select>
    """)

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    expect(div.select(".active-result").length).toBe(1)

    search_field = div.down(".chosen-search-input")
    search_field.value = "h"
    simulant.fire(search_field, "keyup")

    expect(div.select(".active-result").length).toBe(1)
    expect(div.select(".active-result")[0].innerHTML).toBe("oh <em>h</em>ello")
