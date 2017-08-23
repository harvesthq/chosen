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
