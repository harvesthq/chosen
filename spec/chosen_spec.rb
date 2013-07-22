require 'spec_helper'

describe "jQuery version" do
  it "should show results on click" do
    visit '/index.html'
    page.should have_css('.chzn-container')
    find('.chzn-select').should be_invisible
    first_container = first('.chzn-container')
    first_container.click
    first_container.should have_css('.chzn-with-drop')
    
  end
end