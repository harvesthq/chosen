describe "Bugfixes", ->
  it "https://github.com/harvesthq/chosen/issues/2996 - XSS Vulnerability with `include_group_label_in_selected: true`", ->
    tmpl = "
      <select>
        <option value=''></option>
        <optgroup id='xss' label='</script><script>console.log(1)</script>'>
          <option>an xss option</option>
        </optgroup>
      </select>
    "
    div = new Element("div")
    document.body.insert(div)
    div.innerHTML = tmpl

    select = div.down("select")
    new Chosen select,
      include_group_label_in_selected: true

    # open the drop
    container = div.down(".chosen-container")
    simulant.fire(container, "mousedown") # open the drop

    xss_option = container.select(".active-result").last()
    expect(xss_option.innerHTML).toBe "an xss option"

    # trigger the selection of the xss option
    simulant.fire(xss_option, "mouseup")

    # make sure the script tags are escaped correctly
    label_html = container.down("a.chosen-single").innerHTML
    expect(label_html).toContain('&lt;/script&gt;&lt;script&gt;console.log(1)&lt;/script&gt;')

