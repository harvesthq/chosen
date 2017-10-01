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

          div = $("<div>").html(tmpl)
          select = div.find("select")
          select.chosen({search_contains: true, search_in_order: search_in_order_setting})

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

  describe "renders options correctly when they contain characters that require HTML encoding", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
          div = $("<div>").html("""
            <select>
              <option value="A &amp; B">A &amp; B</option>
            </select>
          """)

          div.find("select").chosen({search_in_order: search_in_order_setting})
          div.find(".chosen-container").trigger("mousedown") # open the drop

          expect(div.find(".active-result").length).toBe(1)
          expect(div.find(".active-result").first().html()).toBe("A &amp; B")

          search_field = div.find(".chosen-search-input").first()
          search_field.val("A")
          search_field.trigger("keyup")

          expect(div.find(".active-result").length).toBe(1)
          expect(div.find(".active-result").first().html()).toBe("<em>A</em> &amp; B")

  describe "renders optgroups correctly when they contain html encoded tags", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
          div = $("<div>").html("""
            <select>
              <optgroup label="A &lt;b&gt;hi&lt;/b&gt; B">
                <option value="Item">Item</option>
              </optgroup>
            </select>
          """)

          div.find("select").chosen({search_in_order: search_in_order_setting})
          div.find(".chosen-container").trigger("mousedown") # open the drop

          expect(div.find(".group-result").length).toBe(1)
          expect(div.find(".group-result").first().html()).toBe("A &lt;b&gt;hi&lt;/b&gt; B")

  describe "renders optgroups correctly when they contain characters that require HTML encoding when searching", ->
    for search_in_order_setting in [true, false]
      do (search_in_order_setting) ->
        it "when search_in_order is " + search_in_order_setting, ->
          div = $("<div>").html("""
            <select>
              <optgroup label="A &amp; B">
                <option value="Item">Item</option>
              </optgroup>
            </select>
          """)

          div.find("select").chosen({search_in_order: search_in_order_setting})
          div.find(".chosen-container").trigger("mousedown") # open the drop

          expect(div.find(".group-result").length).toBe(1)
          expect(div.find(".group-result").first().html()).toBe("A &amp; B")

          search_field = div.find(".chosen-search-input").first()
          search_field.val("A")
          search_field.trigger("keyup")

          expect(div.find(".group-result").length).toBe(1)
          expect(div.find(".group-result").first().html()).toBe("<em>A</em> &amp; B")

  describe "finding and highlighting", ->
    setup_results_test = (query, settings = {}) ->
      div = $("<div>").html("""
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
      correct_results_chosen = div.find("select").chosen(settings)
      div.find(".chosen-container").trigger("mousedown") # open the drop
      search_field = div.find(".chosen-search-input")
      search_field.val(query)
      search_field.trigger("keyup")
      div.find(".active-result")
    
    it "treats space literally by default", ->
      results = setup_results_test 'John D'
      expect(results.length).toBe(1)
      expect(results.first().html()).toBe('<em>John D</em>oe Smith')
    it "treats space as term delimiter when search_term_delimiter is true", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true}
      expect(results.length).toBe(4)
      expect(results.eq(0).html()).toBe('<em>John</em> Doe <em>Smi</em>th')
      expect(results.eq(1).html()).toBe('<em>John Smi</em>th')
      expect(results.eq(2).html()).toBe('<em>Smi</em>th <em>John</em>son')
      expect(results.eq(3).html()).toBe('<em>Smi</em>th F. <em>John</em>son')
    it "treats asterix as term delimiter when search_term_delimiter is '*'", ->
      results = setup_results_test 'John*Smi', {search_term_delimiter: '*'}
      expect(results.length).toBe(4)
      expect(results.eq(0).html()).toBe('<em>John</em> Doe <em>Smi</em>th')
    it "respects word boundaries when search_term_delimiter is true", ->
      results = setup_results_test 'John mi', {search_term_delimiter: true}
      expect(results.length).toBe(0)
    it "ignores word boundaries when search_term_delimiter and search_contains are true", ->
      results = setup_results_test 'John mi', {search_term_delimiter: true, search_contains: true}
      expect(results.length).toBe(4)
      expect(results.eq(0).html()).toBe('<em>John</em> Doe S<em>mi</em>th')
      expect(results.eq(1).html()).toBe('<em>John</em> S<em>mi</em>th')
      expect(results.eq(2).html()).toBe('S<em>mi</em>th <em>John</em>son')
      expect(results.eq(3).html()).toBe('S<em>mi</em>th F. <em>John</em>son')
    it "only finds options with terms in correct order when search_in_order is true", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true, search_in_order: true}
      expect(results.length).toBe(2)
      expect(results.eq(0).html()).toBe('<em>John</em> Doe <em>Smi</em>th')
    it "includes spaces between neighbouring terms in highlight", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true, search_in_order: true}
      expect(results.length).toBe(2)
      expect(results.eq(0).html()).toBe('<em>John</em> Doe <em>Smi</em>th')
      expect(results.eq(1).html()).toBe('<em>John Smi</em>th')
    it "includes characters between terms in highlight when search_highlight_full_match is true", ->
      results = setup_results_test 'John Smi', {search_term_delimiter: true, search_highlight_full_match: true}
      expect(results.length).toBe(4)
      expect(results.eq(0).html()).toBe('<em>John Doe Smi</em>th')
      expect(results.eq(1).html()).toBe('<em>John Smi</em>th')
      expect(results.eq(2).html()).toBe('<em>Smith John</em>son')
      expect(results.eq(3).html()).toBe('<em>Smith F. John</em>son')
    it "considers non-ascii characters word-boundaries by default", ->
      results = setup_results_test 'ller', {}
      expect(results.length).toBe(2)
      expect(results.eq(0).html()).toBe('Frank Mø<em>ller</em>')
      expect(results.eq(1).html()).toBe('Frank Ø<em>ller</em>')
    it "does not consider non-ascii characters word-boundaries if search_word_boundary is '^|\\s'", ->
      results = setup_results_test 'ller', {search_word_boundary: '^|\\s'}
      expect(results.length).toBe(0)
    it "correctly highlights terms despite capturing group(s) in search_word_boundary", ->
      results = setup_results_test 'Øller', {search_word_boundary: '(^|\\s|(,))'}
      expect(results.length).toBe(1)
      expect(results.eq(0).html()).toBe('Frank <em>Øller</em>')
    it "does not include redundant '</em><em>' in highlighted results", ->
      results = setup_results_test 'ab bb ba', {search_term_delimiter: true, search_contains: true}
      expect(results.length).toBe(1)
      expect(results.eq(0).html()).toBe('<em>abbbba</em>')

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
