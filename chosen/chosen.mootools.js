(function(){
  /*
  Chosen, a Select Box Enhancer for jQuery and Protoype
  by Patrick Filler for Harvest, http://getharvest.com

  Available for use under the MIT License, http://en.wikipedia.org/wiki/MIT_License

  Copyright (c) 2011 by Harvest
  */

	var Chosen, OptionsParser, get_side_border_padding, root;

	var __bind = function(fn, me){
		return function(){
			return fn.apply(me, arguments);
		};
	};

	root = typeof exports !== "undefined" && exports !== null ? exports : this;

  	Elements.implement({

    	chosen: function(data, options){

			return this.each(function(el){
				return new Chosen(el, data, options);
			});

    	}
	});


  	Chosen = (function(){

		function Chosen(elmn){

			this.set_default_values();
			this.form_field = elmn;
			this.is_multiple = this.form_field.multiple;
			this.default_text_default = this.form_field.multiple ? "Select Some Options" : "Select an Option";
			this.set_up_html();
			this.register_observers();

		}

		Chosen.prototype.set_default_values = function(){

			this.click_test_action = __bind(function(evt){
				return this.test_active_click(evt);
			}, this);

			this.active_field = false;
			this.mouse_on_container = false;
			this.results_showing = false;
			this.result_highlighted = null;
			this.result_single_selected = null;

			return this.choices = 0;

		};

		Chosen.prototype.set_up_html = function(){

			var container_div, dd_top, dd_width, sf_width;

			this.container_id = this.form_field.id + "_chzn";
			this.f_width = $(this.form_field).getCoordinates().width;

			this.default_text = this.form_field.getProperty('title') ? $(this.form_field).getProperty('title') : this.default_text_default;

			container_div = new Element('div', {
				'id': 		this.container_id,
				'class': 	'chzn-container'
			}).setStyles({
				'width': 	(this.f_width + 2)
			});

			if(this.is_multiple){

				container_div.set('html', '<ul class="chzn-choices"><li class="search-field"><input type="text" value="' + this.default_text + '" class="default" style="width:25px;" /></li></ul><div class="chzn-drop" style="left:-9000px;"><ul class="chzn-results"></ul></div>');

			}else{

				container_div.set('html', '<a href="#" class="chzn-single"><span>' + this.default_text + '</span><div><b></b></div></a><div class="chzn-drop" style="left:-9000px;"><div class="chzn-search"><input type="text" /></div><ul class="chzn-results"></ul></div>');

			}

			this.form_field.setStyle('display', 'none').grab(container_div, 'after');
			this.container = $(this.container_id);

			this.container.addClass("chzn-container-" + (this.is_multiple ? "multi" : "single"));
			this.dropdown = this.container.getElement('div.chzn-drop');

			dd_top = this.container.getCoordinates().height;
			dd_width = this.f_width - get_side_border_padding(this.dropdown);
			this.dropdown.setStyles({
				'width': 	dd_width,
				'top': 		dd_top
			});

			this.search_field = this.container.getElement('input');
			this.search_results = this.container.getElement('ul.chzn-results');
			this.search_field_scale();
			this.search_no_results = this.container.getElement('li.no-results');

			if(this.is_multiple){

				this.search_choices = this.container.getElement('ul.chzn-choices');
				this.search_container = this.container.getElement('li.search-field');

			}else{

				this.search_container = this.container.getElement('div.chzn-search');
				this.selected_item = this.container.getElement('.chzn-single');

				sf_width = dd_width - get_side_border_padding(this.search_container) - get_side_border_padding(this.search_field);
				this.search_field.setStyle('width', (sf_width - 25));

			}

			this.results_build();

			return this.set_tab_index();

		};

		Chosen.prototype.register_observers = function(){

			this.container.addEvent("click", __bind(function(evt){
				return this.container_click(evt);
			}, this));

			this.container.addEvent("mouseenter", __bind(function(evt){
				return this.mouse_enter(evt);
			}, this));

			this.container.addEvent("mouseleave", __bind(function(evt){
				return this.mouse_leave(evt);
			}, this));

			this.search_results.addEvent("click", __bind(function(evt){
				return this.search_results_click(evt);
			}, this));

			this.search_results.addEvent("mouseover", __bind(function(evt){
				return this.search_results_mouseover(evt);
			}, this));

			this.search_results.addEvent("mouseout", __bind(function(evt){
				return this.search_results_mouseout(evt);
			}, this));

			this.form_field.addEvent("liszt:updated", __bind(function(evt){
				return this.results_update_field(evt);
			}, this));

			this.search_field.addEvent("blur", __bind(function(evt){
				return this.input_blur(evt);
			}, this));

			this.search_field.addEvent("keyup", __bind(function(evt){
				return this.keyup_checker(evt);
			}, this));

			this.search_field.addEvent("keydown", __bind(function(evt){
				return this.keydown_checker(evt);
			}, this));

			if(this.is_multiple){

				this.search_choices.addEvent("click", __bind(function(evt){
					return this.choices_click(evt);
				}, this));

				return this.search_field.addEvent("focus", __bind(function(evt){
					return this.input_focus(evt);
				}, this));

			}else{

				return this.selected_item.addEvent("focus", __bind(function(evt){
					return this.activate_field(evt);
				}, this));

			}

		};

		Chosen.prototype.container_click = function(evt){

			if(evt && evt.type === "click"){
				evt.stopPropagation();
			}

			if(!this.pending_destroy_click){

				if(!this.active_field){

					if(this.is_multiple){

						this.search_field.value = '';

					}

					$(document).addEvent('click', this.click_test_action);
					this.results_show();

				}else if(!this.is_multiple && evt && ($(evt.target) === this.selected_item || $(evt.target).getParents('a.chzn-single').length)){

					evt.preventDefault();
					this.results_show();

				}

				return this.activate_field();

			}else{

				return this.pending_destroy_click = false;

			}

		};

		Chosen.prototype.mouse_enter = function(){
			return this.mouse_on_container = true;
		};

		Chosen.prototype.mouse_leave = function(){
			return this.mouse_on_container = false;
		};

		Chosen.prototype.input_focus = function(evt){
			if(!this.active_field){
				return setTimeout(this.container_click.bind(this), 50);
			}
		};

		Chosen.prototype.input_blur = function(evt){
			if(!this.mouse_on_container){
				this.active_field = false;
				return setTimeout(this.blur_test.bind(this), 100);
			}
		};

		Chosen.prototype.blur_test = function(evt){
			if(!this.active_field && this.container.hasClass("chzn-container-active")){
				return this.close_field();
			}
		};

		Chosen.prototype.close_field = function(){
			$(document).removeEvent('click', this.click_test_action);

			if(!this.is_multiple){
				this.selected_item.setProperty('tabindex', this.search_field.getProperty('tabindex'));
				this.search_field.setProperty('tabindex', -1);
			}

			this.active_field = false;
			this.results_hide();
			this.container.removeClass("chzn-container-active");
			this.winnow_results_clear();
			this.clear_backstroke();
			this.show_search_field_default();

			return this.search_field_scale();

		};

		Chosen.prototype.activate_field = function(){

			if(!this.is_multiple && !this.active_field){
				this.search_field.setProperty('tabindex', this.selected_item.getProperty('tabindex'));
				this.selected_item.setProperty('tabindex', -1);
			}
			this.container.addClass("chzn-container-active");
			this.active_field = true;
			this.search_field.set('value', this.search_field.get('value'));

			return this.search_field.focus();

		};

		Chosen.prototype.test_active_click = function(evt){

			if($(evt.target).getParents('#' + this.container.id).length){
				return this.active_field = true;
			}else{
				return this.close_field();
			}

		};

		Chosen.prototype.results_build = function(){

			var content, data, startTime, _i, _len, _ref;
			startTime = new Date();
			this.parsing = true;
			this.results_data = OptionsParser.select_to_array(this.form_field);

			if(this.is_multiple && this.choices > 0){

				this.search_choices.getElements("li.search-choice").destroy();
				this.choices = 0;

			}else if(!this.is_multiple){

				this.selected_item.getElements("span").set('text', this.default_text);

			}

			content = '';
			_ref = this.results_data;

			for(_i = 0, _len = _ref.length; _i < _len; _i++){

				data = _ref[_i];
				if(data.group){
					content += this.result_add_group(data);
				}else if(!data.empty){
					content += this.result_add_option(data);
					if(data.selected && this.is_multiple){
						this.choice_build(data);
					}else if(data.selected && !this.is_multiple){
						this.selected_item.getElements("span").set('text', data.text);
					}
				}
			}

			this.show_search_field_default();
			this.search_results.set('html', content);

			return this.parsing = false;

		};

		Chosen.prototype.result_add_group = function(group){

			if(!group.disabled){

				group.dom_id = this.form_field.id + "chzn_g_" + group.id;
				return '<li id="' + group.dom_id + '" class="group-result"><div>'+ group.label + '</div></li>';

			}else{
				return '';
			}

		};

		Chosen.prototype.result_add_option = function(option){

			var classes;
			if(!option.disabled){
				option.dom_id = this.form_field.id + "chzn_o_" + option.id;
				classes = option.selected && this.is_multiple ? [] : ["active-result"];

				if(option.selected){
					classes.push("result-selected");
				}

				if(option.group_id >= 0){
					classes.push("group-option");
				}

				return '<li id="' + option.dom_id + '" class="' + classes.join(' ') + '"><div>'+ option.text + '</div></li>';

			}else{

				return '';

			}

		};

		Chosen.prototype.results_update_field = function(){

			this.result_clear_highlight();
			this.result_single_selected = null;

			return this.results_build();

		};

		Chosen.prototype.result_do_highlight = function(el){

			var high_bottom, high_top, maxHeight, visible_bottom, visible_top;

			if(el){

				this.result_clear_highlight();
				this.result_highlight = el;
				this.result_highlight.addClass("highlighted");
				maxHeight = parseInt(this.search_results.getStyle("maxHeight"), 10);

				visible_top = this.search_results.getScroll().y;
				visible_bottom = maxHeight + visible_top;

				high_top = this.result_highlight.getPosition(this.search_results).y + this.search_results.getScroll().y;
				high_bottom = high_top + this.result_highlight.getCoordinates().height;
				if(high_bottom >= visible_bottom){
					return this.search_results.scrollTo(0, (high_bottom - maxHeight) > 0 ? high_bottom - maxHeight : 0);
				}else if(high_top < visible_top){
					return this.search_results.scrollTo(0, high_top);
				}

			}

		};

		Chosen.prototype.result_clear_highlight = function(){

			if(this.result_highlight){
				this.result_highlight.removeClass("highlighted");
			}
			return this.result_highlight = null;

		};

		Chosen.prototype.results_show = function(){

			var dd_top;
			if(!this.is_multiple){

				this.selected_item.addClass("chzn-single-with-drop");

				if(this.result_single_selected){
					this.result_do_highlight(this.result_single_selected);
				}

			}

			dd_top = this.is_multiple ? this.container.getCoordinates().height : this.container.getCoordinates().height - 1;

			this.dropdown.setStyles({
				"top": dd_top + "px",
				"left": 0
			});

			this.results_showing = true;
			this.search_field.focus();
			this.search_field.set('value', this.search_field.get('value'));

			return this.winnow_results();

		};

		Chosen.prototype.results_hide = function(){

			if(!this.is_multiple){
				this.selected_item.removeClass("chzn-single-with-drop");
			}

			this.result_clear_highlight();
			this.dropdown.setStyles({
				"left": "-9000px"
			});

			return this.results_showing = false;

		};

		Chosen.prototype.set_tab_index = function(el){

			var ti;
			if(($(this.form_field)).getProperty('tabindex')){
				ti = ($(this.form_field)).getProperty('tabindex');
				($(this.form_field)).setProperty('tabindex', -1);

				if(this.is_multiple){
					return this.search_field.setProperty('tabindex', ti);
				}else{
					this.selected_item.setProperty('tabindex', ti);
					return this.search_field.setProperty('tabindex', -1);
				}
			}

		};

		Chosen.prototype.show_search_field_default = function(){

			if(this.is_multiple && this.choices < 1 && !this.active_field){
				this.search_field.set('value', this.default_text);
				return this.search_field.addClass("default");
			}else{
				this.search_field.set('value', "");
				return this.search_field.removeClass("default");
			}
		};

		Chosen.prototype.search_results_click = function(evt){

			var target;
			target = $(evt.target).hasClass("active-result") ? $(evt.target) : $(evt.target).getParent(".active-result");

			if(target){
				this.result_highlight = target;
				return this.result_select();
			}

		};

		Chosen.prototype.search_results_mouseover = function(evt){

			var target;
			target = $(evt.target).hasClass("active-result") ? $(evt.target) : $(evt.target).getParent(".active-result");
			if(target){
				return this.result_do_highlight(target);
			}

		};

		Chosen.prototype.search_results_mouseout = function(evt){

			if($(evt.target).hasClass("active-result") || $(evt.target).getParent('.active-result')){
				return this.result_clear_highlight();
			}
		};

		Chosen.prototype.choices_click = function(evt){

			evt.preventDefault();
			if(this.active_field && !($(evt.target).hasClass("search-choice") || $(evt.target).getParent('.search-choice')) && !this.results_showing){
				return this.results_show();
			}

		};

		Chosen.prototype.choice_build = function(item){
			var choice_id, link;

			choice_id = this.form_field.id + "_chzn_c_" + item.id;
			this.choices += 1;

			var el = new Element('li', {'id': choice_id})
						.addClass('search-choice')
						.set('html', '<span>' + item.text + '</span><a href="#" class="search-choice-close" rel="' + item.id + '"></a>');

			this.search_container.grab(el, 'before');

			link = $(choice_id).getElement("a");
			return link.click(__bind(function(evt){
				return this.choice_destroy_link_click(evt);
			}, this));

		};

		Chosen.prototype.choice_destroy_link_click = function(evt){

			evt.preventDefault();

			this.pending_destroy_click = true;
			return this.choice_destroy($(evt.target));

		};

		Chosen.prototype.choice_destroy = function(link){

			this.choices -= 1;
			this.show_search_field_default();
			if(this.is_multiple && this.choices > 0 && this.search_field.value.length < 1){
				this.results_hide();
			}
			this.result_deselect(link.getProperty("rel"));
			return link.getParent('li').destroy();

		};

		Chosen.prototype.result_select = function(){
			var high, high_id, item, position;

			if(this.result_highlight){

				high = this.result_highlight;
				high_id = high.getProperty("id");
				this.result_clear_highlight();
				high.addClass("result-selected");

				if(this.is_multiple){
					this.result_deactivate(high);
				}else{
					this.result_single_selected = high;
				}

				position = high_id.substr(high_id.lastIndexOf("_") + 1);
				item = this.results_data[position];
				item.selected = true;
				this.form_field.options[item.select_index].selected = true;

				if(this.is_multiple){
					this.choice_build(item);
				}else{
					this.selected_item.getElement("span").set('text', item.text);
				}

				this.results_hide();
				this.search_field.set('value', "");
				($(this.form_field)).fireEvent("change");

				return this.search_field_scale();

			}

		};

		Chosen.prototype.result_activate = function(el){

			return el.addClass("active-result").setStyle('display', 'block');

		};

		Chosen.prototype.result_deactivate = function(el){

			return el.removeClass("active-result").setStyle('display', 'none');

		};

		Chosen.prototype.result_deselect = function(pos){
			var result, result_data;

			result_data = this.results_data[pos];
			result_data.selected = false;
			this.form_field.options[result_data.select_index].selected = false;
			result = $(this.form_field.id + "chzn_o_" + pos);
			result.removeClass("result-selected").addClass("active-result").setStyle('display', 'block');
			this.result_clear_highlight();
			this.winnow_results();

			($(this.form_field)).fireEvent("change");
			return this.search_field_scale();

		};

		Chosen.prototype.results_search = function(evt){

			if(this.results_showing){
				return this.winnow_results();
			}else{
				return this.results_show();
			}

		};

		Chosen.prototype.winnow_results = function(){
			var found, option, part, parts, regex, result_id, results, searchText, startTime, startpos, text, zregex, _i, _j, _len, _len2, _ref;

			startTime = new Date();
			this.no_results_clear();
			results = 0;
			searchText = this.search_field.get('value') === this.default_text ? "" : this.search_field.get('value').trim();
			regex = new RegExp('^' + searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i');
			zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i');
			_ref = this.results_data;

			for(_i = 0, _len = _ref.length; _i < _len; _i++){

				option = _ref[_i];

				if(!option.disabled && !option.empty){

					if(option.group){
						$(option.dom_id).setStyle('display', 'none');
					}else if(!(this.is_multiple && option.selected)){
						found = false;
						result_id = this.form_field.id + "chzn_o_" + option.id;

						if(regex.test(option.text)){
							found = true;
							results += 1;
						}else if(option.text.indexOf(" ") >= 0 || option.text.indexOf("[") === 0){
							parts = option.text.replace(/\[|\]/g, "").split(" ");

							if(parts.length){

								for(_j = 0, _len2 = parts.length; _j < _len2; _j++){
									part = parts[_j];

									if(regex.test(part)){
										found = true;
										results += 1;
									}

								}

							}

						}

						if(found){

							if(searchText.length){

								startpos = option.text.search(zregex);
								text = option.text.substr(0, startpos + searchText.length) + '</em>' + option.text.substr(startpos + searchText.length);
								text = text.substr(0, startpos) + '<em>' + text.substr(startpos);

							}else{

								text = option.text;

							}

							if($(result_id).get('html') !== text){
								$(result_id).set('html', text);
							}

							this.result_activate($(result_id));

							if(option.group_id != null){
								$(this.results_data[option.group_id].dom_id).setStyle('display', 'block');
							}

						}else{

							if(this.result_highlight && result_id === this.result_highlight.getProperty('id')){

								this.result_clear_highlight();

							}

							this.result_deactivate($(result_id));

						}

					}

				}

			}

			if(results < 1 && searchText.length){
				return this.no_results(searchText);
			}else{
				return this.winnow_results_set_highlight();
			}

		};

		Chosen.prototype.winnow_results_clear = function(){
			var li, lis, _i, _len, _results;

			this.search_field.set('value', '');
			lis = this.search_results.getElements("li");
			_results = [];

			for(_i = 0, _len = lis.length; _i < _len; _i++){

				li = lis[_i];
				li = $(li);
				_results.push(li.hasClass("group-result") ? li.setStyle('display', 'block') : !this.is_multiple || !li.hasClass("result-selected") ? this.result_activate(li) : void 0);

			}

			return _results;

		};

		Chosen.prototype.winnow_results_set_highlight = function(){
			var do_high;

			if(!this.result_highlight){

				do_high = this.search_results.getElement(".active-result");

				if(do_high){
					return this.result_do_highlight(do_high);
				}

			}

		};

		Chosen.prototype.no_results = function(terms){
			var no_results_html;

			no_results_html = new Element('li', {'class': 'no-results'}).set('html', 'No results match "<span></span>"');
			no_results_html.getElement("span").set('text', terms);
			return this.search_results.grab(no_results_html);

		};

		Chosen.prototype.no_results_clear = function(){
			return this.search_results.getElements(".no-results").destroy();
		};

		Chosen.prototype.keydown_arrow = function(){
			var first_active, next_sib;

			if(!this.result_highlight){

				first_active = this.search_results.getElement("li.active-result");

				if(first_active){
					this.result_do_highlight($(first_active));
				}

			}else if(this.results_showing){

				next_sib = this.result_highlight.getNext("li.active-result");

				if(next_sib){
					this.result_do_highlight(next_sib);
				}

			}

			if(!this.results_showing){
				return this.results_show();
			}

		};

		Chosen.prototype.keyup_arrow = function(){
			var prev_sibs;

			if(!this.results_showing && !this.is_multiple){

				return this.results_show();

			}else if(this.result_highlight){

				prev_sibs = this.result_highlight.getAllPrevious("li.active-result");

				if(prev_sibs.length){
					return this.result_do_highlight(prev_sibs[0]);
				}else{

					if(this.choices > 0){
						this.results_hide();
					}

					return this.result_clear_highlight();

				}
			}
		};

		Chosen.prototype.keydown_backstroke = function(){

			if(this.pending_backstroke){
				this.choice_destroy(this.pending_backstroke.getElement("a"));
				return this.clear_backstroke();
			}else{
				this.pending_backstroke = this.search_container.getLast("li.search-choice");
				return this.pending_backstroke.addClass("search-choice-focus");
			}
		};

		Chosen.prototype.clear_backstroke = function(){

			if(this.pending_backstroke){
				this.pending_backstroke.removeClass("search-choice-focus");
			}
			return this.pending_backstroke = null;

		};

		Chosen.prototype.keyup_checker = function(evt){
			var stroke, _ref;

			stroke = (_ref = evt.code) != null ? _ref : evt.keyCode;
			this.search_field_scale();

			switch (stroke){
				case 8:

					if(this.is_multiple && this.backstroke_length < 1 && this.choices > 0){
						return this.keydown_backstroke();
					}else if(!this.pending_backstroke){
						this.result_clear_highlight();
						return this.results_search();
					}
					break;

				case 13:

					evt.preventDefault();
					if(this.results_showing){
						return this.result_select();
					}
					break;

				case 9:
				case 13:
				case 38:
				case 40:
				case 16:
					break;

				default:
					return this.results_search();

			}

		};

		Chosen.prototype.keydown_checker = function(evt){
			var stroke, _ref;

			stroke = (_ref = evt.code) != null ? _ref : evt.keyCode;
			this.search_field_scale();

			if(stroke !== 8 && this.pending_backstroke){
				this.clear_backstroke();
			}

			switch(stroke){
				case 8:
					this.backstroke_length = this.search_field.value.length;
					break;

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

		};

		Chosen.prototype.search_field_scale = function(){
			var dd_top, div, h, style, style_block, styles, w, _i, _len;

			if(this.is_multiple){

				h = 0;
				w = 0;
				style_block = "position:absolute; left: -1000px; top: -1000px; display:none;";
				styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'];

				for (_i = 0, _len = styles.length; _i < _len; _i++){
					style = styles[_i];
					style_block += style + ":" + this.search_field.getStyle(style) + ";";
				}

				div = new Element('div').setStyles({
					'position': 'absolute',
					'left': 	-1000,
					'top': 		-1000,
					'display': 	'none'
				}).set('text', this.search_field.get('value'));

				$(document.body).grab(div);

				w = div.getCoordinates().width + 25;
				div.destroy();

				if(w > this.f_width - 10){
					w = this.f_width - 10;
				}

				this.search_field.setStyles({
					'width': w + 'px'
				});

				dd_top = this.container.getCoordinates().height;
				return this.dropdown.setStyles({
					"top": dd_top + "px"
				});
			}

		};

		return Chosen;

	})();

	get_side_border_padding = function(elmt){
		var side_border_padding;

		return side_border_padding = elmt.getCoordinates().width - elmt.getCoordinates().width;
	};

	root.get_side_border_padding = get_side_border_padding;

	OptionsParser = (function(){

		function OptionsParser(){
			this.group_index = 0;
			this.sel_index = 0;
			this.parsed = [];
		}

		OptionsParser.prototype.add_node = function(child){

			if(child.nodeName === "OPTGROUP"){
				return this.add_group(child);
			}else{
				return this.add_option(child);
			}
		};

		OptionsParser.prototype.add_group = function(group){
			var group_id, option, _i, _len, _ref;

			group_id = this.sel_index + this.group_index;
			this.parsed.push({
				id: group_id,
				group: true,
				label: group.label,
				position: this.group_index,
				children: 0,
				disabled: group.disabled
			});

			_ref = group.childNodes;

			for (_i = 0, _len = _ref.length; _i < _len; _i++){
				option = _ref[_i];
				this.add_option(option, group_id, group.disabled);
			}

			return this.group_index += 1;

		};

		OptionsParser.prototype.add_option = function(option, group_id, group_disabled){
			var _ref;

			if(option.nodeName === "OPTION"){

				if(option.text !== ""){

					if(group_id || group_id === 0){
						this.parsed[group_id].children += 1;
					}

					this.parsed.push({
						id: this.sel_index + this.group_index,
						select_index: this.sel_index,
						value: option.value,
						text: option.text,
						selected: option.selected,
						disabled: (_ref = group_disabled === true) != null ? _ref : {
							group_disabled: option.disabled
						},
						group_id: group_id
					});

				}else{

					this.parsed.push({
						empty: true
					});

				}

				return this.sel_index += 1;

			}

		};

		return OptionsParser;
	})();

	OptionsParser.select_to_array = function(select){
		var child, parser, _i, _len, _ref;

		parser = new OptionsParser();
		_ref = select.childNodes;

		for(_i = 0, _len = _ref.length; _i < _len; _i++){
			child = _ref[_i];
			parser.add_node(child);
		}

		return parser.parsed;
	};

	root.OptionsParser = OptionsParser;

}).call(this);
