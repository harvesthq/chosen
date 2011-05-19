/*!

Chosen for Protoype.js
by Patrick Filler at Harvest

Copyright (c) 2011 Harvest

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

Chosen = Class.create();

Chosen.prototype = {
  
  active_field : false,
  mouse_on_container : false,

  result_highlighted : null,
  result_single_selected : null,

  choices: 0,
  
  // HTML Templates
  single_temp : new Template('<a href="#" class="chzn-single">#{default}</a><div class="chzn-drop" style="display:none;"><div class="chzn-search"><input type="text" /></div><ul class="chzn-results"></ul></div>'),
  multi_temp : new Template('<ul class="chzn-choices"><li class="search-field"><input type="text" value="#{default}" class="default" /></li></ul><div class="chzn-drop" style="display:none;"><ul class="chzn-results"></ul></div>'),
  
  choice_temp : new Template('<li class="search-choice" id="#{id}"><span>#{choice}</span><a href="#" class="search-choice-close" rel="#{position}"></a></li>'),
  group_temp : new Template('<li id="#{id}" class="group-result" style="display:none;">#{label}</li>'),
  result_temp : new Template('<li id="#{id}" class="active-result">#{result}</li>'),
  no_results_temp : new Template('<li class="no-results">No results match "<span>#{terms}</span>"</li>'),

  initialize: function(el){
    if(!Prototype.Browser.IE7 && !Prototype.Browser.IE6){
      this.form_field = el;
      this.is_multiple = this.form_field.multiple;
      this.form_field.observe("liszt:updated", this.results_update_field.bindAsEventListener(this));
  
      this.default_text_default = (this.form_field.multiple) ? "Select Some Options" : "Select an Option";

      this.click_test_action = this.test_active_click.bindAsEventListener(this);
    
      this.set_up_html();
      this.register_observers();
    }
  },
  
  set_up_html: function(){
    this.container_id = this.form_field.id + "_chzn";
    
    var f_width = (this.form_field.getStyle("width")) ? parseInt( this.form_field.getStyle("width"), 10 ) : this.form_field.getWidth();
    var container_props = {
      'id': this.container_id,
      'class':'chzn-container',
      'style':'width:'+ f_width +'px'
    };
    
    this.default_text = this.form_field.readAttribute('title') ? this.form_field.readAttribute('title') : this.default_text_default
    
    var base_template = ( this.is_multiple ) ? new Element('div', container_props).update( this.multi_temp.evaluate({ "default": this.default_text}) ) : new Element('div', container_props).update( this.single_temp.evaluate({ "default":this.default_text }) );

    this.form_field.hide().insert({ after: base_template });

    this.container = $(this.container_id);
    this.container.addClassName( "chzn-container-" + ((this.is_multiple) ? "multi" : "single") );
    this.dropdown = this.container.down('div.chzn-drop');
    
    var dd_top = this.container.getHeight();
    var dd_width = (f_width - get_side_border_padding(this.dropdown));

    this.dropdown.setStyle({"width": dd_width  + "px", "top": dd_top + "px"});

    this.search_field = this.container.down('input');
    this.search_results = this.container.down('ul.chzn-results');
    
    this.search_no_results = this.container.down('li.no-results');
    
    if( !this.is_multiple ){
      this.search_container = this.container.down('div.chzn-search');
      this.selected_item = this.container.down('.chzn-single');
      this.selected_item.observe("click", this.results_toggle.bindAsEventListener(this));
      var sf_width = (dd_width - get_side_border_padding(this.search_container) - get_side_border_padding(this.search_field));
      this.search_field.setStyle( {"width" : sf_width + "px"} );
    }
    else{
      this.search_choices = this.container.down('ul.chzn-choices');
      this.search_container = this.container.down('li.search-field');
      this.search_choices.observe("click", this.choices_click.bindAsEventListener(this));
    }

    this.results_parse_field();
  },
  
  register_observers: function(){
    this.container.observe("click", this.container_click.bindAsEventListener(this));
    
    this.container.observe("mouseenter", this.mouse_enter.bindAsEventListener(this));
    this.container.observe("mouseleave", this.mouse_leave.bindAsEventListener(this));
    
    this.search_field.observe("blur", this.input_blur.bindAsEventListener(this));
    this.search_field.observe("keyup", this.keyup_checker.bindAsEventListener(this));
    this.search_field.observe("keydown", this.keydown_checker.bindAsEventListener(this));
    this.set_tab_index();
    
    if( !this.is_multiple ){ this.selected_item.observe("focus", this.input_focus.bindAsEventListener(this)); }
    else{ this.search_field.observe("focus", this.input_focus.bindAsEventListener(this)); }
  },
  
  set_tab_index: function(el){
    if(this.form_field.tabIndex){
      var ti = this.form_field.tabIndex;
      this.form_field.tabIndex = -1;

      this.search_field.tabIndex = ti;
      if( !this.is_multiple ){ this.selected_item.tabIndex = ti; }
    }
  },
  
  container_click: function(evt){
    if(evt && evt.type=="click"){ evt.preventDefault(); }
    if( !this.pending_destroy_click ){
      if(!this.active_field){
        if(this.is_multiple){ this.search_field.clear(); }
        document.observe("click", this.click_test_action);
        this.results_show();
      }
      this.search_field.value = this.search_field.value;
      this.search_field.focus();

      this.container.addClassName("chzn-container-active");
      this.active_field = true;
    }
    else{ this.pending_destroy_click = false; }
  },
  
  mouse_enter: function(){ this.mouse_on_container = true; },
  mouse_leave: function(){ this.mouse_on_container = false; },
  
  input_focus: function(evt){
    if(!this.active_field){ setTimeout( this.container_click.bind(this) , 100 ); }
  },
  
  input_blur: function(evt){
    if( !this.mouse_on_container ){
      this.active_field = false;
      setTimeout( this.blur_test.bind(this) , 150 );
    }
  },
  
  blur_test: function(evt){
    if( !this.active_field ){ this.close_field(); }
  },
  
  test_active_click: function(evt){
    if( evt.target.up( '#' + this.container.identify() ) ){ this.active_field = true; }
    else{ this.close_field(); }
  },
  
  close_field: function(){
    this.active_field = false;
    this.results_hide();
    
    this.container.removeClassName("chzn-container-active");
    this.winnow_results_clear();
    this.clear_backstroke();
    
    if( this.is_multiple && this.choices < 1 ){
      this.search_field.value = this.default_text;
      this.search_field.addClassName("default");
    }
  },
  
  results_show: function(){
    if( !this.is_multiple ){
      this.selected_item.addClassName('chzn-single-with-drop');
      if( this.result_single_selected ){ this.result_do_highlight( this.result_single_selected ); }
    }

    this.dropdown.setStyle({"top": this.container.getHeight() + "px"});
    this.dropdown.show();
    
    this.search_field.focus();
    this.search_field.value = this.search_field.value;
    
    this.winnow_results();
  },
  
  results_toggle: function(evt){
    evt.preventDefault();
    if( this.active_field ){
      if( this.dropdown.visible() ){ this.results_hide(); }
      else{ this.results_show(); }
    }
  },
  
  results_hide: function(){
    if( !this.is_multiple ){ this.selected_item.removeClassName('chzn-single-with-drop'); }
    this.result_clear_highlight();
    this.dropdown.hide();
  },
  
  results_build: function(){
    this.choices = 0;
    var data = this.results_data;
    
    var i;
    for( i = 0;  i<data.length; i++){
      if( data[i].group ){ this.result_add_group( data[i] ); }
      else{ this.result_add_option( data[i] ); }
    }
    
    this.parsing = false;
    this.winnow_results();
  },
  
  results_parse_field: function(){
    this.parsing = true;
    
    if( this.search_results.select("li").length ){ this.search_results.update(""); }
    if( this.is_multiple && this.search_choices.select("li.search-choice").length ){ this.search_choices.select("li.search-choice").invoke("remove"); }
    
    this.results_data = select_to_array.parse( this.form_field );
    this.results_build();
  },
  
  results_update_field: function(){
    this.result_clear_highlight();
    this.results_parse_field();
  },
  
  result_add_group: function(group){
    if( !group.disabled ){
      group.dom_id = this.form_field.id + "chzn_g_" + group.id;
      this.search_results.insert( this.group_temp.evaluate({"id":group.dom_id, "label":group.label}) );
    }
  },
  
  result_add_option: function(option){
    if( !option.disabled ){
      option.dom_id = (this.form_field.id + "chzn_o_" + option.id);
      this.search_results.insert( this.result_temp.evaluate({"id":option.dom_id,"result":option.text}) );
    
      var result = $(option.dom_id);

      if( option.selected ){
        this.result_do_highlight( result );
        this.result_select();
      }

      if( option.group_id >= 0 ){ result.addClassName("group-option"); }

      result.observe('click',this.result_click.bindAsEventListener(this));
      result.observe('mouseover',this.result_over.bindAsEventListener(this));
      result.observe('mouseout', this.result_clear_highlight.bindAsEventListener(this));
    }
  },
  
  result_over: function(evt){
    this.result_do_highlight( (evt.target.hasClassName("active-result")) ? evt.target : evt.target.up(".active-result") );
  },
  
  result_do_highlight: function(el){
    this.result_clear_highlight();
    
    this.result_highlight = el;
    this.result_highlight.addClassName('highlighted');
    
    var maxHeight = parseInt(this.search_results.getStyle('maxHeight'), 10);
    var visible_top = this.search_results.scrollTop;
    var visible_bottom = maxHeight + visible_top;
    
    var high_top = this.result_highlight.positionedOffset().top;
    var high_bottom = high_top + this.result_highlight.getHeight();
    
    if( high_bottom > visible_bottom ){ this.search_results.scrollTop = (high_bottom - maxHeight > 0) ? high_bottom - maxHeight : 0; }
    else if( high_top < visible_top ){ this.search_results.scrollTop = high_top; }
  },
  result_clear_highlight: function(){
    if( this.result_highlight ){
      this.result_highlight.removeClassName('highlighted');
      this.result_highlight = null;
    }
  },
  
  result_click: function(evt){
    this.result_highlight = (evt.target.hasClassName("active-result")) ? evt.target : evt.target.up(".active-result");
    this.result_select();
  },
  
  result_select: function(){
    if(this.result_highlight){

      var high = this.result_highlight;
      this.result_clear_highlight();

      high.addClassName("result-selected");
      if( this.is_multiple ){ this.result_deactivate(high); }
      else{ this.result_single_selected = high; }

      var position = high.id.substr( high.id.lastIndexOf("_") + 1 );
      var item = this.results_data[position];
      this.form_field.options[item.select_index].selected = true;

      if( this.is_multiple ){ this.choice_build( item ); }
      else { this.selected_item.innerHTML = item.text; }

      this.results_hide();

      if(!this.parsing){ this.winnow_results(); }

      this.search_field.value = "";

      if(typeof Event.simulate === 'function'){ this.form_field.simulate("change"); }
    }
  },
  
  result_activate: function(el){
    el.addClassName("active-result").show();
  },
  
  result_deactivate: function(el){
    el.removeClassName("active-result").hide();
  },
  
  result_deselect: function(pos){
    var result_data = this.results_data[pos];
    this.form_field.options[result_data.select_index].selected = false;
    var result = $(this.form_field.id + "chzn_o_" + pos);
    result.removeClassName("result-selected").addClassName("active-result").show();
    
    this.result_clear_highlight();
    this.winnow_results();
    
    if(typeof Event.simulate === 'function'){ this.form_field.simulate("change"); }
  },
  
  results_search: function(){
    if( !this.dropdown.visible() ){ this.results_show(); }
    else{ this.winnow_results(); }
  },
  
  winnow_results: function(){
    this.no_results_clear();
    
    var results = 0;

    var searchText = (this.search_field.value == this.default_text) ? "" : this.search_field.value.strip();
    var regex = new RegExp('^' + searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i');
    
    // SPOT
    var i;
    for( i = 0; i<this.results_data.length; i+=1 ){
      var option = this.results_data[i];
       
      if(!option.disabled){
        if(option.group){ $(option.dom_id).hide(); }
        else if(!(this.is_multiple && $(option.dom_id).hasClassName('result-selected'))){
          var found = false;
        
          var result_id = this.form_field.id + "chzn_o_" + option.id;
          if( regex.test( option.text ) ){
            found = true; results += 1;
          }
          else if( option.text.indexOf(" ") >= 0){
            var parts = option.text.split(" ");
            if( parts.length ){
              var j;
              for( j = 0; j<parts.length; j++){
                if( regex.test( parts[j] ) ){ found = true; results += 1; }
              }
            }
          }
        
          if( found ){
            var zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i');
            var startpos = option.text.search( zregex );

            var text = option.text.substr(0,startpos + searchText.length) + '</em>' + option.text.substr(startpos + searchText.length);
            text = text.substr(0,startpos) + '<em>' + text.substr(startpos);

            $(result_id).innerHTML = text;
            
            this.result_activate( $(result_id) );
            
            if( option.group_id >= 0 ){ $( this.results_data[option.group_id].dom_id ).show(); }
          }
          else{
            if( $(result_id) === this.result_highlight ){ this.result_clear_highlight(); }
            this.result_deactivate( $(result_id) );
          }
        
        }
      }
    }
    
    if( results < 1 && searchText.length ){ this.no_results( searchText );  }
    else { this.winnow_results_set_highlight(); }
  },
  
  winnow_results_clear: function(){
    this.search_field.clear();
    var lis = this.search_results.select("li");
    var i;
    
    for( i = 0; i<lis.length; i++){
      var li = lis[i];
      if( li.hasClassName("group-result") ){ li.show(); }
      else if( !this.is_multiple || !li.hasClassName("result-selected") ){ this.result_activate( li ); }
    }
  },
  
  winnow_results_set_highlight: function(){
    if(!this.result_highlight){
      var do_high = this.search_results.down(".active-result");
      if(do_high){ this.result_do_highlight( do_high ); }
    }
  },
  
  no_results: function(terms){
    this.search_results.insert( this.no_results_temp.evaluate({"terms":terms.escapeHTML()}) );
  },
  
  no_results_clear: function(){
    var nr = null;
    while( nr = this.search_results.down(".no-results") ){ nr.remove(); }
  },
  
  choices_click: function(evt){
    evt.preventDefault();
    if( this.active_field && !(evt.target.hasClassName('search-choice') || evt.target.up('.search-choice')) && !this.dropdown.visible() ){ this.results_show(); }
  },
  
  choice_build: function(item){
    var choice_id = this.form_field.id + "_chzn_c_" + item.id;
    this.choices += 1;
    this.search_container.insert({ before: this.choice_temp.evaluate({"id":choice_id, "choice":item.text, "position":item.id}) });
    var link = $(choice_id).down('a');
    link.observe("click", this.choice_destroy_link_click.bindAsEventListener(this));
  },
  
  choice_destroy_link_click: function(evt){
    evt.preventDefault();
    this.pending_destroy_click = true;
    this.choice_destroy( evt.target );
  },
  
  choice_destroy: function(link){
    this.choices -= 1;
    
    if( this.is_multiple && this.choices > 0 && this.search_field.value.length < 1 ){ this.results_hide(); }
    
    this.result_deselect(link.readAttribute("rel"));
    link.up('li').remove();
    
    if( this.choices < 1 ){ this.close_field(); }
  },
  
  keydown_arrow: function(){
    var actives = this.search_results.select("li.active-result");
    if( actives.length ){
      if( !this.result_highlight ){ this.result_do_highlight( actives.first() ); }
      else if( this.dropdown.visible() ){
        var sibs = this.result_highlight.nextSiblings();
        var nexts = sibs.intersect(actives);
        if( nexts.length ){ this.result_do_highlight(nexts.first()); }
      }
      if( !this.dropdown.visible() ){ this.results_show(); }
    }
  },
  
  keyup_arrow: function(){
    if( this.result_highlight ){
      var sibs = this.result_highlight.previousSiblings();
      var actives = this.search_results.select("li.active-result");
      var prevs = sibs.intersect(actives);
      
      if( prevs.length ){ this.result_do_highlight(prevs.first()); }
      else{
        if(this.choices > 0){ this.results_hide(); }
        this.result_clear_highlight();
      }
    }
  },
  
  keydown_backstroke: function(){
    if( this.pending_backstroke ){
      this.choice_destroy( this.pending_backstroke.down("a") );
      this.clear_backstroke();  
    }
    else{
      this.pending_backstroke = this.search_container.siblings("li.search-choice").last();
      this.pending_backstroke.addClassName("search-choice-focus");
    }
  },
  
  clear_backstroke: function(){
    if( this.pending_backstroke ){ this.pending_backstroke.removeClassName("search-choice-focus"); }
    this.pending_backstroke = null;
  },
  
  keyup_checker: function(evt){
    var stroke = evt.which || evt.keyCode;

    switch(stroke){
      case 8:
        if( this.is_multiple && this.backstroke_length < 1 && this.choices > 0 ) this.keydown_backstroke();
        else if( !this.pending_backstroke ){ this.results_search(); }
        break;
      case 13:
        evt.preventDefault();
        if( this.dropdown.visible() ){ this.result_select(); }
        break;
      case 9:
      case 13:
      case 38:
      case 40:
        break;
      default:
        this.results_search();
        break;
    }
  },
  
  keydown_checker: function(evt){
    var stroke = evt.which || evt.keyCode;
    
    if(stroke !== 8 && this.pending_backstroke) this.clear_backstroke();

    switch(stroke){
      case 8:
        this.backstroke_length = this.search_field.value.length;
      case 9:
        this.mouse_on_container = false;
        break;
      case 13:
        evt.preventDefault();
        break;        
      case 38:
        evt.preventDefault();
        this.keyup_arrow();
        break;
      case 40:
        this.keydown_arrow();
        break;
    }
  }

};

var get_side_border_padding = function(item){
  var layout = new Element.Layout(item);
  return layout.get("border-left") + layout.get("border-right") + layout.get("padding-left") + layout.get("padding-right");
}

var select_to_array = {
  parse: function(select){
    var children = select.children;
    var opt_array = [];

    var group_index = 0;
    var sel_index = 0;
    
    var i;
    
    for( i = 0; i<children.length; i++){
      if( children[i].nodeName==="OPTGROUP" ){
        var group = children[i];
        var group_options = group.children;
        var group_id = opt_array.length;

        opt_array.push({ id: group_id, group: true, label: group.label, position:group_index, children: group_options.length, disabled:group.disabled });

        for( var j=0; j<group_options.length; j++ ){
          opt_array.push( select_to_array.parse_option( group_options[j], opt_array.length, sel_index, group_id, group.disabled ) );
          sel_index += 1;
        }
        
        group_index += 1;
      }
      else if( children[i].text!=="" || i>0 ){
        opt_array.push( select_to_array.parse_option( children[i], opt_array.length, sel_index ) );
        sel_index += 1;
      }
    }

    return opt_array;
  },
  
  parse_option: function(option, opt_id, select_index, group_id, group_disabled){
    var opt = { id:opt_id, select_index:select_index, value:option.value, text:option.text, selected:option.selected, disabled:option.disabled }
    if(group_id || group_id===0){
      opt.group_id = group_id;
      if( group_disabled ){ opt.disabled = group_disabled; }
    }
    return opt;
  }
};

document.observe('dom:loaded',function() {
  $$(".chzn-select").each(function(el){ new Chosen( el ); });
});