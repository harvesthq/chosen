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

  it "renders optgroups correctly when they contain html encoded tags", ->
    div = $("<div>").html("""
      <select>
        <optgroup label="A &lt;b&gt;hi&lt;/b&gt; B">
          <option value="Item">Item</option>
        </optgroup>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    expect(div.find(".group-result").length).toBe(1)
    expect(div.find(".group-result").first().html()).toBe("A &lt;b&gt;hi&lt;/b&gt; B")

  it "renders optgroups correctly when they contain characters that require HTML encoding when searching", ->
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

  it "renders no results message correctly when it contains characters that require HTML encoding", ->
    div = $("<div>").html("""
      <select>
        <option value="Item">Item</option>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    search_field = div.find(".chosen-search-input").first()
    search_field.val("&")
    search_field.trigger("keyup")

    expect(div.find(".no-results").length).toBe(1)
    expect(div.find(".no-results").first().html().trim()).toBe("No results match <span>&amp;</span>")

    search_field.val("&amp;")
    search_field.trigger("keyup")

    expect(div.find(".no-results").length).toBe(1)
    expect(div.find(".no-results").first().html().trim()).toBe("No results match <span>&amp;amp;</span>")

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

  describe "respects word boundaries when not using search_contains", ->
    div = $("<div>").html("""
      <select>
        <option value="(lparen">(lparen</option>
        <option value="&lt;langle">&lt;langle</option>
        <option value="[lbrace">[lbrace</option>
        <option value="{lcurly">{lcurly</option>
        <option value="¡upsidedownbang">¡upsidedownbang</option>
        <option value="¿upsidedownqmark">¿upsidedownqmark</option>
        <option value=".period">.period</option>
        <option value="-dash">-dash</option>
        <option value='"leftquote'>"leftquote</option>
        <option value="'leftsinglequote">'leftsinglequote</option>
        <option value="“angledleftquote">“angledleftquote</option>
        <option value="‘angledleftsinglequote">‘angledleftsinglequote</option>
        <option value="«guillemet">«guillemet</option>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    search_field = div.find(".chosen-search-input")

    div.find("option").each () ->
      boundary_thing = this.value.slice(1)
      it "correctly finds words that start after a(n) #{boundary_thing}", ->
        search_field.val(boundary_thing)
        search_field.trigger("keyup")
        expect(div.find(".active-result").length).toBe(1)
        expect(div.find(".active-result")[0].innerText.slice(1)).toBe(boundary_thing)

  it "does not clear search text or highlight first suggestion when holding ctrl/cmd and selecting multiple items", () ->
    div = $("<div>").html("""
      <select multiple>
        <option></option>
        <option>Betty Holberton</option>
        <option>Radia Perlman</option>
        <option>Barbara Liskov</option>
        <option>Frances Allen</option>
        <option>Shafi Goldwasser</option>
        <option>Maria Klawe</option>
        <option>Jean E. Sammet</option>
        <option>Adele Goldberg</option>
        <option>Jeannette Wing</option>
        <option>Éva Tardos</option>
        <option>Lynn Conway</option>
        <option>Karen Spärck Jones</option>
        <option>Sophie Wilson</option>
        <option>Wendy Hall</option>
      </select>
    """)

    div.find("select").chosen()
    div.find(".chosen-container").trigger("mousedown") # open the drop

    search_field = div.find(".chosen-search-input")
    search_field.val("s").trigger("keyup")

    results = div.find(".chosen-results")
    first_result = results.find("li:nth-of-type(1)")
    second_result = results.find("li:nth-of-type(2)")

    expect(first_result.prop("class")).toContain("highlighted")

    mouseup_with_meta = $.Event("mouseup")
    mouseup_with_meta.metaKey = true
    second_result.mouseover().trigger(mouseup_with_meta)

    expect(div.find(".search-choice").length).toBe(1)
    expect(search_field.val()).toBe("s")
    expect(first_result.prop("class")).not.toContain("highlighted")

    third_result = results.find("li:nth-of-type(3)")

    mouseup_with_ctrl = $.Event("mouseup")
    mouseup_with_ctrl.ctrlKey = true
    third_result.mouseover().trigger(mouseup_with_ctrl)

    expect(div.find(".search-choice").length).toBe(2)
    expect(search_field.val()).toBe("s")
    expect(first_result.prop("class")).not.toContain("highlighted")

  it "clears search text and highlights first suggestion without ctrl/cmd and selecting multiple items without hide_results_on_select", () ->
    div = $("<div>").html("""
      <select multiple>
        <option></option>
        <option>Betty Holberton</option>
        <option>Radia Perlman</option>
        <option>Barbara Liskov</option>
        <option>Frances Allen</option>
        <option>Shafi Goldwasser</option>
        <option>Maria Klawe</option>
        <option>Jean E. Sammet</option>
        <option>Adele Goldberg</option>
        <option>Jeannette Wing</option>
        <option>Éva Tardos</option>
        <option>Lynn Conway</option>
        <option>Karen Spärck Jones</option>
        <option>Sophie Wilson</option>
        <option>Wendy Hall</option>
      </select>
    """)

    div.find("select").chosen(hide_results_on_select: false)
    div.find(".chosen-container").trigger("mousedown") # open the drop

    search_field = div.find(".chosen-search-input")
    search_field.val("s").trigger("keyup")

    results = div.find(".chosen-results")
    first_result = results.find("li:nth-of-type(1)")
    second_result = results.find("li:nth-of-type(2)")

    expect(first_result.prop("class")).toContain("highlighted")

    second_result.mouseover().mouseup()

    expect(div.find(".search-choice").length).toBe(1)
    expect(search_field.val()).toBe("")
    expect(results.find("li:nth-of-type(1)").prop("class")).toContain("highlighted")
