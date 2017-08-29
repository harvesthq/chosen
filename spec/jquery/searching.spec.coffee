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

  it "matches in non-ascii languages like Chinese when selecting a single item", ->
    div = $("<div>").html("""
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

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".active-result").length).toBe(12)

    search_field = div.find(".chosen-search-input").first()
    search_field.val("一")
    search_field.trigger("keyup")

    expect(div.find(".active-result").length).toBe(1)
    expect(div.find(".active-result")[0].innerHTML).toBe("<em>一</em>")

  it "matches in non-ascii languages like Chinese when selecting a single item with search_contains", ->
    div = $("<div>").html("""
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

    div.find("select").chosen({search_contains: true})
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".active-result").length).toBe(12)

    search_field = div.find(".chosen-search-input").first()
    search_field.val("一")
    search_field.trigger("keyup")

    expect(div.find(".active-result").length).toBe(2)
    expect(div.find(".active-result")[0].innerHTML).toBe("<em>一</em>")
    expect(div.find(".active-result")[1].innerHTML).toBe("十<em>一</em>")

  it "matches in non-ascii languages like Chinese when selecting multiple items", ->
    div = $("<div>").html("""
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

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".active-result").length).toBe(12)

    search_field = div.find(".chosen-search-input")
    search_field.val("一")
    search_field.trigger("keyup")

    expect(div.find(".active-result").length).toBe(1)
    expect(div.find(".active-result")[0].innerHTML).toBe("<em>一</em>")

  it "matches in non-ascii languages like Chinese when selecting multiple items with search_contains", ->
    div = $("<div>").html("""
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

    div.find("select").chosen({search_contains: true})
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".active-result").length).toBe(12)

    search_field = div.find(".chosen-search-input")
    search_field.val("一")
    search_field.trigger("keyup")

    expect(div.find(".active-result").length).toBe(2)
    expect(div.find(".active-result")[0].innerHTML).toBe("<em>一</em>")
    expect(div.find(".active-result")[1].innerHTML).toBe("十<em>一</em>")

  it "highlights results correctly when multiple words are present", ->
    div = $("<div>").html("""
      <select>
        <option value="oh hello">oh hello</option>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".active-result").length).toBe(1)

    search_field = div.find(".chosen-search-input")
    search_field.val("h")
    search_field.trigger("keyup")

    expect(div.find(".active-result").length).toBe(1)
    expect(div.find(".active-result")[0].innerHTML).toBe("oh <em>h</em>ello")
