describe "Bugfixes", ->
  it "https://github.com/harvesthq/chosen/issues/2996 - XSS Vulnerability with `include_group_label_in_selected: true`", ->
    tmpl = "
      <select>
        <option value=''></option>
        <optgroup label='</script><script>console.log(1)</script>'>
          <option>an xss option</option>
        </optgroup>
      </select>
    "

    div = $("<div>").html(tmpl)
    select = div.find("select")

    select.chosen
      include_group_label_in_selected: true

    # open the drop
    container = div.find(".chosen-container")
    container.trigger("mousedown")

    xss_option = container.find(".active-result").last()
    expect(xss_option.html()).toBe "an xss option"

    # trigger the selection of the xss option
    xss_option.trigger("mouseup")

    # make sure the script tags are escaped correctly
    label_html = container.find("a.chosen-single").html()
    expect(label_html).toContain('&lt;/script&gt;&lt;script&gt;console.log(1)&lt;/script&gt;')
