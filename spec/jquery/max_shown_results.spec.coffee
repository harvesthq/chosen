describe "search", ->
  it "should display only matching items when entering a search term", ->
    tmpl = "
          <select data-placeholder='Choose a Country...'>
            <option value=''></option>
            <option value='United States'>United States</option>
            <option value='United Kingdom'>United Kingdom</option>
            <option value='Afghanistan'>Afghanistan</option>
          </select>
        "
    div = $("<div>").html(tmpl)
    select = div.find("select")
    select.chosen()

    container = div.find(".chosen-container")
    container.trigger("mousedown") # open the drop
    # Expect all results to be shown
    results = div.find(".active-result")
    expect(results.length).toBe(3)

    # Enter some text in the search field.
    search_field = div.find(".chosen-search input").first()
    search_field.val("Afgh")
    search_field.trigger('keyup')

    # Expect to only have one result: 'Afghanistan'.
    results = div.find(".active-result")
    expect(results.length).toBe(1)
    expect(results.first().text()).toBe "Afghanistan"

  it "should only show max_shown_results items in results", ->
    tmpl = "
          <select data-placeholder='Choose a Country...'>
            <option value=''></option>
            <option value='United States'>United States</option>
            <option value='United Kingdom'>United Kingdom</option>
            <option value='Afghanistan'>Afghanistan</option>
          </select>
        "
    div = $("<div>").html(tmpl)
    select = div.find("select")
    select.chosen({max_shown_results: 1 })

    container = div.find(".chosen-container")
    container.trigger("mousedown") # open the drop
    results = div.find(".active-result")
    expect(results.length).toBe(1)

    # Enter some text in the search field.
    search_field = div.find(".chosen-search input").first()
    search_field.val("United")
    search_field.trigger("keyup")

    # Showing only one result: the one that occurs first.
    results = div.find(".active-result")
    expect(results.length).toBe(1)
    expect(results.first().text()).toBe "United States"

    # Showing still only one result, but not the first one.
    search_field.val("United Ki")
    search_field.trigger("keyup")
    results = div.find(".active-result")
    expect(results.length).toBe(1)
    expect(results.first().text()).toBe "United Kingdom"
