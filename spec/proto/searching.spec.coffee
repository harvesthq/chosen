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
