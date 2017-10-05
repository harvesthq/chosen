describe "search", ->
  it "should display only matching items when entering a search term", ->
    this_test = testcase ['United States', 'United Kingdom', 'Afghanistan']
    
    do this_test.open_drop
    
    # Expect all results to be shown
    expect(this_test.get_results().length).toBe 3
    
    #Type something
    this_test.set_search("Afgh")
    
    # Expect to only have one result: 'Afghanistan'.
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].text()).toBe "Afghanistan"
    
  it 'should only show max_shown_results items in results', ->
    this_test = testcase ['United States', 'United Kingdom', 'Afghanistan'], {max_shown_results: 1}
    
    do this_test.open_drop
    
    # Expect only one result due to max_shown_results
    expect(this_test.get_results().length).toBe 1
    
    # Enter some text in the search field.
    this_test.set_search("United")
    
    # Showing only one result: the one that occurs first.
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].text()).toBe "United States"

    # Enter some more text in the search field.
    this_test.set_search("United Ki")
    
    # Still only one result, but not the first one.
    expect(this_test.get_results().length).toBe 1
    expect(this_test.get_results()[0].text()).toBe "United Kingdom"