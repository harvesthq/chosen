describe "Events", ->
  it "should fire the right events", ->
    this_test = testcase ['', 'United States', 'United Kingdom', 'Afghanistan']
    
    # Track order of events
    event_sequence = []
    this_test.div.onEvt 'input', (evt) -> event_sequence.push evt.type
    this_test.div.onEvt 'change', (evt) -> event_sequence.push evt.type
    
    do this_test.open_drop
    
    this_test.click_result 2
    
    expect(event_sequence).toEqual ['input', 'change']