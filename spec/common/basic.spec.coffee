describe "Basic setup", ->
  # Check existence of jQuery object / Chosen global
  fw_basictest()
  
  it "should create very basic chosen", ->
    this_test = testcase ['', 'United States', 'United Kingdom', 'Afghanistan']
    
    # very simple check that the necessary elements have been created
    ["container", "container-single", "single", "default"].forEach (clazz)->
      el = this_test.div.find(".chosen-#{clazz}")[0]
      expect(type_is_dom_elm el.dom_el).toBe true
    expect(this_test.get_val()).toBe ''
    
    do this_test.open_drop
    expect(this_test.container.hasClass('chosen-container-active')).toBe true
    
    expect(this_test.get_results().length).toBe 3
    
    this_test.click_result 2
    
    #check that the select was updated correctly
    expect(this_test.get_val()).toBe "Afghanistan"

  describe "data-placeholder", ->
    it "should render", ->
      this_test = testcase ['', 'United States', 'United Kingdom', 'Afghanistan'], {}, 'data-placeholder="Choose a Country..."'
      expect(this_test.div.find(".chosen-single > span")[0].text()).toBe "Choose a Country..."
      
    it "should render with special characters", ->
      this_test = testcase ['', 'United States', 'United Kingdom', 'Afghanistan'], {}, 'data-placeholder="&lt;None&gt;"'
      expect(this_test.div.find(".chosen-single > span")[0].text()).toBe "<None>"
      
  describe "disabled fieldset", ->
    it "should render as disabled", ->
      # More complicated tests need to pass the HTML directly to tmpl_testcase
      this_test = testcase """
        <fieldset disabled>
          <select data-placeholder='Choose a Country...'>
            <option value=''></option>
            <option value='United States'>United States</option>
            <option value='United Kingdom'>United Kingdom</option>
            <option value='Afghanistan'>Afghanistan</option>
          </select>
        </fieldset>
      """
      expect(this_test.container.hasClass("chosen-disabled")).toBe true