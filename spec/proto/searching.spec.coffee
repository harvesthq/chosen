describe "Searching", ->
  describe "should not match the actual text of HTML entities", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
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
          new Chosen(select, {search_contains: true, search_in_order: search_in_order_setting})

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

  describe "renders options correctly when they contain characters that require HTML encoding", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
          div = new Element("div")
          div.update("""
            <select>
              <option value="A &amp; B">A &amp; B</option>
            </select>
          """)

          new Chosen(div.down("select"), {search_in_order: search_in_order_setting})
          simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

          expect(div.select(".active-result").length).toBe(1)
          expect(div.down(".active-result").innerHTML).toBe("A &amp; B")

          search_field = div.down(".chosen-search-input")
          search_field.value = "A"
          simulant.fire(search_field, "keyup")

          expect(div.select(".active-result").length).toBe(1)
          expect(div.down(".active-result").innerHTML).toBe("<em>A</em> &amp; B")

  describe "renders optgroups correctly when they contain characters that require HTML encoding", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
          div = new Element("div")
          div.update("""
            <select>
              <optgroup label="A &lt;b&gt;hi&lt;/b&gt; B">
                <option value="Item">Item</option>
              </optgroup>
            </select>
          """)

          new Chosen(div.down("select"), {search_in_order: search_in_order_setting})
          simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

          expect(div.select(".group-result").length).toBe(1)
          expect(div.down(".group-result").innerHTML).toBe("A &lt;b&gt;hi&lt;/b&gt; B")

  describe "renders optgroups correctly when they contain characters that require HTML encoding when searching", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
          div = new Element("div")
          div.update("""
            <select>
              <optgroup label="A &amp; B">
                <option value="Item">Item</option>
              </optgroup>
            </select>
          """)

          new Chosen(div.down("select"), {search_in_order: search_in_order_setting})
          simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

          expect(div.select(".group-result").length).toBe(1)
          expect(div.down(".group-result").innerHTML).toBe("A &amp; B")

          search_field = div.down(".chosen-search-input")
          search_field.value = "A"
          simulant.fire(search_field, "keyup")

          expect(div.select(".group-result").length).toBe(1)
          expect(div.down(".group-result").innerHTML).toBe("<em>A</em> &amp; B")






  describe "finding and highlighting", ->
    setup_results_test = (query, settings = {}) ->
      div = new Element("div")
      div.update("""
        <select>
          <option value="abbbba">abbbba</option>
          <option value="Frank Miller">Frank Miller</option>
          <option value="Frank Møller">Frank Møller</option>
          <option value="Frank Øller">Frank Øller</option>
          <option value="John Doe Smith">John Doe Smith</option>
          <option value="John Smith">John Smith</option>
          <option value="Smith Johnson">Smith Johnson</option>
          <option value="Smith F. Johnson">Smith F. Johnson</option>
        </select>
      """)
      correct_results_chosen = new Chosen(div.down("select"), settings)
      simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop
      search_field = div.down(".chosen-search-input")
      search_field.value = query
      simulant.fire(search_field, "keyup")
      div.select(".active-result")
    
    it "treats space literally by default", ->
      results = setup_results_test 'John D'
      expect(results.length).toBe(1)
      expect(results[0].innerHTML).toBe('<em>John D</em>oe Smith')
    it "treats space as term delimiter when search_term_delimiter is true", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true}
      expect(results.length).toBe(4)
      expect(results[0].innerHTML).toBe('<em>John</em> Doe <em>Smi</em>th')
      expect(results[1].innerHTML).toBe('<em>John Smi</em>th')
      expect(results[2].innerHTML).toBe('<em>Smi</em>th <em>John</em>son')
      expect(results[3].innerHTML).toBe('<em>Smi</em>th F. <em>John</em>son')
    it "treats asterix as term delimiter when search_term_delimiter is '*'", ->
      results = setup_results_test 'John*Smi', {search_term_delimiter: '*'}
      expect(results.length).toBe(4)
      expect(results[0].innerHTML).toBe('<em>John</em> Doe <em>Smi</em>th')
    it "respects word boundaries when search_term_delimiter is true", ->
      results = setup_results_test 'John mi', {search_term_delimiter: true}
      expect(results.length).toBe(0)
    it "ignores word boundaries when search_term_delimiter and search_contains are true", ->
      results = setup_results_test 'John mi', {search_term_delimiter: true, search_contains: true}
      expect(results.length).toBe(4)
      expect(results[0].innerHTML).toBe('<em>John</em> Doe S<em>mi</em>th')
      expect(results[1].innerHTML).toBe('<em>John</em> S<em>mi</em>th')
      expect(results[2].innerHTML).toBe('S<em>mi</em>th <em>John</em>son')
      expect(results[3].innerHTML).toBe('S<em>mi</em>th F. <em>John</em>son')
    it "only finds options with terms in correct order when search_in_order is true", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true, search_in_order: true}
      expect(results.length).toBe(2)
      expect(results[0].innerHTML).toBe('<em>John</em> Doe <em>Smi</em>th')
    it "includes spaces between neighbouring terms in highlight", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true, search_in_order: true}
      expect(results.length).toBe(2)
      expect(results[0].innerHTML).toBe('<em>John</em> Doe <em>Smi</em>th')
      expect(results[1].innerHTML).toBe('<em>John Smi</em>th')
    it "includes characters between terms in highlight when search_highlight_full_match is true", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true, search_highlight_full_match: true}
      expect(results.length).toBe(4)
      expect(results[0].innerHTML).toBe('<em>John Doe Smi</em>th')
      expect(results[1].innerHTML).toBe('<em>John Smi</em>th')
      expect(results[2].innerHTML).toBe('<em>Smith John</em>son')
      expect(results[3].innerHTML).toBe('<em>Smith F. John</em>son')
    it "considers non-ascii characters word-boundaries by default", ->
      results = setup_results_test 'ller', {}
      expect(results.length).toBe(2)
      expect(results[0].innerHTML).toBe('Frank Mø<em>ller</em>')
      expect(results[1].innerHTML).toBe('Frank Ø<em>ller</em>')
    it "does not consider non-ascii characters word-boundaries if search_word_boundary is '^|\\s'", ->
      results = setup_results_test 'ller', {search_word_boundary: '^|\\s'}
      expect(results.length).toBe(0)
    it "correctly highlights terms despite capturing group(s) in search_word_boundary", ->
      results = setup_results_test 'Øller', {search_word_boundary: '(^|\\s|(,))'}
      expect(results.length).toBe(1)
      expect(results[0].innerHTML).toBe('Frank <em>Øller</em>')
    it "does not include redundant '</em><em>' in highlighted results", ->
      results = setup_results_test 'ab bb ba', {search_term_delimiter: true, search_contains: true}
      expect(results.length).toBe(1)
      expect(results[0].innerHTML).toBe('<em>abbbba</em>')








  it "renders no results message correctly when it contains characters that require HTML encoding", ->
    div = new Element("div")
    div.update("""
      <select>
        <option value="Item">Item</option>
      </select>
    """)

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    search_field = div.down(".chosen-search-input")
    search_field.value = "&"
    simulant.fire(search_field, "keyup")

    expect(div.select(".no-results").length).toBe(1)
    expect(div.down(".no-results").innerHTML.trim()).toBe("No results match <span>&amp;</span>")

    search_field.value = "&amp;"
    simulant.fire(search_field, "keyup")

    expect(div.select(".no-results").length).toBe(1)
    expect(div.down(".no-results").innerHTML.trim()).toBe("No results match <span>&amp;amp;</span>")

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

  describe "respects word boundaries when not using search_contains", ->
    div = new Element("div")
    div.update("""
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

    new Chosen(div.down("select"))
    simulant.fire(div.down(".chosen-container"), "mousedown") # open the drop

    search_field = div.down(".chosen-search-input")

    div.select("option").forEach (option) ->
      boundary_thing = option.value.slice(1)
      it "correctly finds words that start after a(n) #{boundary_thing}", ->
        search_field.value = boundary_thing
        simulant.fire(search_field, "keyup")
        expect(div.select(".active-result").length).toBe(1)
        expect(div.select(".active-result")[0].innerText.slice(1)).toBe(boundary_thing)
