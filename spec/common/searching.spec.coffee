describe "Searching", ->
  it "should not match the actual text of HTML entities", ->
    this_test = testcase {
      '': ''
      'This & That': 'This &amp; That'
      'This < That': 'This &lt; That'
    }
    do this_test.open_drop
    
    expect(this_test.get_results().length).toBe 2

    # Search for the html entity by name
    this_test.set_search 'mp'
    
    # There should be no results
    expect(this_test.get_results().length).toBe 0
    
  it "renders options correctly when they contain characters that require HTML encoding", ->
    this_test = testcase ['A &amp; B']
    do this_test.open_drop
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].html()).toBe "A &amp; B"
    this_test.set_search 'A'
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].html()).toBe "<em>A</em> &amp; B"
    
  it "renders optgroups correctly when they contain html encoded tags", ->
    this_test = testcase """
      <select>
        <optgroup label="A &lt;b&gt;hi&lt;/b&gt; B">
          <option value="Item">Item</option>
        </optgroup>
      </select>
    """
    do this_test.open_drop
    expect(this_test.get_result_groups().length).toBe 1
    expect(this_test.get_result_groups()[0].html()).toBe "A &lt;b&gt;hi&lt;/b&gt; B"

  it "renders optgroups correctly when they contain characters that require HTML encoding when searching", ->
    this_test = testcase """
      <select>
        <optgroup label="A &amp; B">
          <option value="Item">Item</option>
        </optgroup>
      </select>
    """
    do this_test.open_drop
    expect(this_test.get_result_groups().length).toBe 1
    expect(this_test.get_result_groups()[0].html()).toBe "A &amp; B"
    this_test.set_search 'A'
    expect(this_test.get_result_groups().length).toBe 1
    expect(this_test.get_result_groups()[0].html()).toBe "<em>A</em> &amp; B"
    
  it "renders no results message correctly when it contains characters that require HTML encoding", ->
    this_test = testcase ['Item']
    do this_test.open_drop
    
    this_test.set_search '&'
    expect(this_test.div.find(".no-results").length).toBe 1
    expect(this_test.div.find(".no-results")[0].html().trim()).toBe "No results match <span>&amp;</span>"
    
    this_test.set_search '&amp;'
    expect(this_test.div.find(".no-results").length).toBe 1
    expect(this_test.div.find(".no-results")[0].html().trim()).toBe "No results match <span>&amp;amp;</span>"

  it "matches in non-ascii languages like Chinese when selecting a single item", ->
    this_test = testcase ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二']
    do this_test.open_drop
    expect(this_test.get_results().length).toBe 12
    this_test.set_search "一"
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].html()).toBe "<em>一</em>"

  it "matches in non-ascii languages like Chinese when selecting a single item with search_contains", ->
    this_test = testcase ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'], {search_contains: true}
    do this_test.open_drop
    expect(this_test.get_results().length).toBe 12
    this_test.set_search "一"
    expect(this_test.get_results().length).toBe 2
    expect(this_test.get_results()[0].html()).toBe "<em>一</em>"
    expect(this_test.get_results()[1].html()).toBe "十<em>一</em>"

  it "matches in non-ascii languages like Chinese when selecting multiple items", ->
    this_test = testcase ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'], {}, 'multi'
    do this_test.open_drop
    expect(this_test.get_results().length).toBe 12
    this_test.set_search "一"
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].html()).toBe "<em>一</em>"
    
  it "matches in non-ascii languages like Chinese when selecting multiple items with search_contains", ->
    this_test = testcase ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'], {search_contains: true}, 'multi'
    do this_test.open_drop
    expect(this_test.get_results().length).toBe 12
    this_test.set_search "一"
    expect(this_test.get_results().length).toBe 2
    expect(this_test.get_results()[0].html()).toBe "<em>一</em>"
    expect(this_test.get_results()[1].html()).toBe "十<em>一</em>"

  it "highlights results correctly when multiple words are present", ->
    this_test = testcase ['oh hello']
    do this_test.open_drop
    expect(this_test.get_results().length).toBe 1
    this_test.set_search "h"
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].html()).toBe "oh <em>h</em>ello"
    
  describe "respects word boundaries when not using search_contains", ->
    this_test = testcase ['(lparen', '&lt;langle', '[lbrace', '{lcurly', '¡upsidedownbang', '¿upsidedownqmark', '.period', '-dash', '"leftquote', "'leftsinglequote", '“angledleftquote', '‘angledleftsinglequote', '«guillemet']
    this_test.div.find("option").forEach (option) ->
      boundary_thing = option.dom_el.value.slice(1)
      it "correctly finds words that start after a(n) #{boundary_thing}", ->
        this_test.set_search boundary_thing
        expect(this_test.get_results().length).toBe 1
        expect(this_test.get_results()[0].text().slice(1)).toBe(boundary_thing)