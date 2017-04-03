describe "set_selection", ->
  it "allows setting single selection programmatically", ->
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

    expect(select.val()).toEqual('')
    chosen = select.data('chosen')
    chosen.set_selection('United Kingdom')
    expect(select.val()).toEqual('United Kingdom')

    displayValue = select.next('.chosen-container').find('.chosen-single').text()
    expect(displayValue).toEqual('United Kingdom')

  it "throws Invalid Value if trying to select non-existent item", ->
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

    expect(select.val()).toEqual('')
    chosen = select.data('chosen')
    expect(->
      chosen.set_selection('Blarg')).toThrow('Invalid value: Blarg')
    
  it "allows setting multiple selections programmatically", ->
    tmpl = "
        <select multiple data-placeholder='Choose a Country...'>
          <option value=''></option>
          <option value='United States'>United States</option>
          <option value='United Kingdom'>United Kingdom</option>
          <option value='Afghanistan'>Afghanistan</option>
        </select>
      "
    div = $("<div>").html(tmpl)
    select = div.find("select")
    select.chosen()

    chosen = select.data('chosen')
    chosen.set_selection(['United States', 'United Kingdom'])
    expect(select.val()).toEqual(['United States', 'United Kingdom'])

    displayValues = select
      .next('.chosen-container')
      .find('.chosen-choices li.search-choice').map(->
        $(this).text()).toArray()
    expect(displayValues).toEqual(['United States', 'United Kingdom'])

