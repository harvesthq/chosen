/*
NOTES:
  This is a YUI Port of the jQuery Chosen.
  http://harvesthq.github.io/chosen/
  
USAGE EXAMPLE:
  YUI().use('node','yui-chosen', function(Y) {
    Y.all('.yui-chosen').each(function(ele) {
      ele.plug(Y.Chosen, {
        no_results_text: "Nothing found dummy.",
        disable_search_threshold: 4,
        max_selected_options: 2,
        allow_single_deselect: true,
        width: "500px"
      });
      ele.on('change', function(e) {
        var value = null;
        if (e.currentTarget.getDOMNode().type == 'select-multiple') {
          var value = [];
          e.currentTarget.all('option').each(function(opt) {
            if (opt.get('selected')) {
              value.push(opt.get('value'));
            }
          });
        } else {
          value = e.currentTarget.get('value');
        }
      });
    });
  });
*/
YUI.add('yui-chosen', function (Y) {
  Y.namespace('Chosen');
  function YUIChosen(config) {
    YUIChosen.superclass.constructor.apply(this, [config.host.getDOMNode(), config]);
  }
  // When plugged into a node instance, the plugin will be 
  // available on the "chosen" property.
  YUIChosen.NS = "chosen"

  Y.extend(YUIChosen, AbstractChosen, {
    setup: function() {
      if (!this.form_field.id) { this.form_field.id = Y.guid(); }
      this.form_field_yui = Y.one('#'+this.form_field.getAttribute('id'));
      this.current_selectedIndex = this.form_field.selectedIndex;
      return this.is_rtl = this.form_field_yui.hasClass("chzn-rtl");
    },
    finish_setup: function() {
      return this.form_field_yui.addClass('chzn-done');
    },
    set_up_html: function() {
      var container_classes, container_props;
      this.container_id = this.form_field.id.length ? this.form_field.id.replace(/[^\w]/g, '_') : this.generate_field_id();
      this.container_id += "_chzn";
      container_classes = ["chzn-container"];
      container_classes.push("chzn-container-" + (this.is_multiple ? "multi" : "single"));
      if (this.inherit_select_classes && this.form_field.className) {
        container_classes.push(this.form_field.className);
      }
      if (this.is_rtl) {
        container_classes.push("chzn-rtl");
      }
      container_props = {
        'id': this.container_id,
        'class': container_classes.join(' '),
        'style': "width: " + (this.container_width()) + ";",
        'title': this.form_field.title
      };
      this.container = Y.Node.create(Y.Lang.sub('<div id="{id}" class="{class}" style="{style}" title="{title}"></div>',container_props));
      if (this.is_multiple) {
        this.container.setContent('<ul class="chzn-choices"><li class="search-field"><input type="text" value="" placeholder="' + this.default_text + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="chzn-drop"><ul class="chzn-results"></ul></div>');
      } else {
        this.container.setContent('<a href="javascript:void(0)" class="chzn-single chzn-default" tabindex="-1"><span>' + this.default_text + '</span><div><b></b></div></a><div class="chzn-drop"><div class="chzn-search"><input type="text" autocomplete="off" placeholder="search" /></div><ul class="chzn-results"></ul></div>');
      }
      this.form_field_yui.hide().insert(this.container, 'after');
      this.dropdown = this.container.one('div.chzn-drop');
      this.search_field = this.container.one('input');
      this.search_results = this.container.one('ul.chzn-results');
      this.search_field_scale();
      this.search_no_results = this.container.one('li.no-results');
      if (this.is_multiple) {
        this.search_choices = this.container.one('ul.chzn-choices');
        this.search_container = this.container.one('li.search-field');
      } else {
        this.search_container = this.container.one('div.chzn-search');
        this.selected_item = this.container.one('.chzn-single');
      }
      this.results_build();
      this.set_tab_index();
      this.set_label_behavior();
      return this.form_field_yui.fire("liszt:ready", {
        chosen: this
      }, this);
    },
    register_observers: function() {
      this.container.on('mousedown', this.container_mousedown, this);
      this.container.on('mouseup', this.container_mouseup, this);
      this.container.on('mouseenter', this.mouse_enter, this);
      this.container.on('mouseleave', this.mouse_leave, this);

      this.search_results.on('mouseup', this.search_results_mouseup, this);
      this.search_results.on('mouseover', this.search_results_mouseover, this);
      this.search_results.on('mouseout', this.search_results_mouseout, this);
      this.search_results.on('mousewheel', this.search_results_mousewheel, this);

      this.form_field_yui.on('liszt:updated', this.results_update_field, this);
      this.form_field_yui.on('liszt:activate', this.activate_field, this);
      this.form_field_yui.on('liszt:open', this.container_mousedown, this);

      this.search_field.on('blur', this.input_blur, this);
      this.search_field.on('keyup', this.keyup_checker, this);
      this.search_field.on('keydown', this.keydown_checker, this);
      this.search_field.on('focus', this.input_focus, this);

      if (this.is_multiple) {
        return this.search_choices.on('click', function(e) {
          this.choices_click(e);
        }, this);
      } else {
        return this.container.on('click', function(e) {
          e.preventDefault();
        }, this);
      }
    },
    search_field_disabled: function() {
      this.is_disabled = this.form_field_yui.getAttribute('disabled');
      if (this.is_disabled) {
        this.container.addClass('chzn-disabled');
        this.search_field.getDOMNode().disabled = true;
        if (!this.is_multiple) {
          this._evt_selected_focus.detach();
        }
        return this.close_field();
      } else {
        this.container.removeClass('chzn-disabled');
        this.search_field.getDOMNode().disabled = false;
        if (!this.is_multiple) {
          this._evt_selected_focus = this.selected_item.on('focus', this.activate_action, this);
          return this._evt_selected_focus;
        }
      }
    },
    container_mousedown: function(e) {
      if (!this.is_disabled) {
        if (e && e.type === "mousedown" && !this.results_showing) {
          e.preventDefault();
        }
        if (!(e != null && e.target.hasClass("search-choice-close"))) {
          if (!this.active_field) {
            if (this.is_multiple) {
              this.search_field.set('value', null);
            }
            this._evt_body_click = Y.one('body').on('click', this.click_test_action, this);
            this.results_show();
          } else if (!this.is_multiple && e && ((e.target === this.selected_item) || e.target.ancestor("a.chzn-single"))) {
            e.preventDefault();
            this.results_toggle();
          }
          return this.activate_field();
        }
      }
    },
    container_mouseup: function(e) {
      if (e.target.get('tagName') === "ABBR" && !this.is_disabled) {
        return this.results_reset(e);
      }
    },
    search_results_mousewheel: function(evt) {
      var delta, _ref1, _ref2;
      delta = -((_ref1 = evt.originalEvent) != null ? _ref1.wheelDelta : void 0) || ((_ref2 = evt.originialEvent) != null ? _ref2.detail : void 0);
      if (delta != null) {
        evt.preventDefault();
        if (evt.type === 'DOMMouseScroll') {
          delta = delta * 40;
        }
        return this.search_results.scrollTop(delta + this.search_results.scrollTop());
      }
    },
    blur_test: function(evt) {
      if (!this.active_field && this.container.hasClass("chzn-container-active")) {
        return this.close_field();
      }
    },
    close_field: function() {
      this._evt_body_click.detach();

      this.active_field = false;
      this.results_hide();
      this.container.removeClass("chzn-container-active");
      this.clear_backstroke();
      this.show_search_field_default();
      return this.search_field_scale();
    },
    activate_field: function() {
      this.container.addClass("chzn-container-active");
      this.active_field = true;
      this.search_field.set('value', this.search_field.get('value'));
      return this.search_field.focus();
    },
    test_active_click: function(evt) {
      if (evt.target.ancestor('#' + this.container_id)) {
        return this.active_field = true;
      } else {
        return this.close_field();
      }
    },
    results_build: function() {
      this.parsing = true;
      this.selected_option_count = null;
      this.results_data = SelectParser.select_to_array(this.form_field);
      if (this.is_multiple) {
        if (this.search_choices.all("li.search-choice")) {
          this.search_choices.all("li.search-choice").remove();
        }
      } else if (!this.is_multiple) {
        this.single_set_selected_text();
        if (this.disable_search || this.form_field.options.length <= this.disable_search_threshold) {
          this.search_field.getDOMNode().readOnly = true;
          this.container.addClass("chzn-container-single-nosearch");
        } else {
          this.search_field.getDOMNode().readOnly = false;
          this.container.removeClass("chzn-container-single-nosearch");
        }
      }
      this.update_results_content(this.results_option_build({
        first: true
      }));
      this.search_field_disabled();
      this.show_search_field_default();
      this.search_field_scale();
      return this.parsing = false;
    },
    result_add_group: function(group) {
      group.dom_id = this.container_id + "_g_" + group.array_index;
      return Y.Lang.sub('<li id="{id}" class="group-result"><div>{content}</div></li>', {id: group.dom_id, content: group.label});
    },
    result_do_highlight: function(el) {
      var high_bottom, high_top, maxHeight, visible_bottom, visible_top;
      if (el) {
        this.result_clear_highlight();
        this.result_highlight = el;
        this.result_highlight.addClass("highlighted");
        maxHeight = parseInt(this.search_results.getStyle("maxHeight"), 10);
        visible_top = this.search_results.get('scrollTop');
        visible_bottom = maxHeight + visible_top;
        high_top = (this.result_highlight.get('region').top - this.search_results.get('region').top) + this.search_results.get('scrollTop');
        high_bottom = high_top + this.result_highlight.get('region').height;
        if (high_bottom >= visible_bottom) {
          return this.search_results.set('scrollTop', (high_bottom - maxHeight) > 0 ? high_bottom - maxHeight : 0);
        } else if (high_top < visible_top) {
          return this.search_results.set('scrollTop',high_top);
        }
      }
    },
    result_clear_highlight: function() {
      if (this.result_highlight) {
        this.result_highlight.removeClass("highlighted");
      }
      return this.result_highlight = null;
    },
    results_show: function() {
      if (this.is_multiple && this.max_selected_options <= this.choices_count()) {
        this.form_field_yui.fire("liszt:maxselected", {
          chosen: this
        }, this);
        return false;
      }
      this.container.addClass("chzn-with-drop");
      this.form_field_yui.fire("liszt:showing_dropdown", {
        chosen: this
      }, this);
      this.results_showing = true;
      this.search_field.focus();
      this.search_field.set('value', this.search_field.get('value'));
      return this.winnow_results();
    },
    update_results_content: function(content) {
      return this.search_results.setContent(content);
    },
    results_hide: function() {
      if (this.results_showing) {
        this.result_clear_highlight();
        this.container.removeClass("chzn-with-drop");
        this.form_field_yui.fire("liszt:hiding_dropdown", {
          chosen: this
        }, this);
      }
      return this.results_showing = false;
    },
    set_tab_index:function(el) {
      var ti;
      if (this.form_field_yui.getAttribute("tabindex")) {
        ti = this.form_field_yui.getAttribute("tabindex");
        this.form_field_yui.setAttribute("tabindex", -1);
        return this.search_field.setAttribute("tabindex", ti);
      }
    },
    set_label_behavior: function() {
      this.form_field_label = this.form_field_yui.ancestor("label");
      if (!this.form_field_label && this.form_field.getAttribute('id')) {
        this.form_field_label = Y.one("label[for='" + this.form_field.getAttribute('id') + "']");
      }
      if (this.form_field_label) {
        return this.form_field_label.on('click', function(e) {
          if (this.is_multiple) {
            return this.container_mousedown(e);
          } else {
            return this.activate_field();
          }
        }, this);
      }
    },
    show_search_field_default: function() {
      if (this.is_multiple && this.choices_count() < 1 && !this.active_field) {
        this.search_field.set('value',this.default_text);
        return this.search_field.addClass("default");
      } else {
        this.search_field.set("value","");
        this.search_field.set("placeholder",null);
        return this.search_field.removeClass("default");
      }
    },
    search_results_mouseup: function(evt) {
      var target;
      target = evt.target.hasClass("active-result") ? evt.target : evt.target.ancestor(".active-result");
      if (target) {
        this.result_highlight = target;
        this.result_select(evt);
        return this.search_field.focus();
      }
    },
    search_results_mouseover: function(evt) {
      var target;
      target = evt.target.hasClass("active-result") ? evt.target : evt.target.ancestor(".active-result");
      if (target) {
        return this.result_do_highlight(target);
      }
    },
    search_results_mouseout: function(evt) {
      if (evt.target.hasClass("active-result" || evt.target.ancestor('.active-result'))) {
        return this.result_clear_highlight();
      }
    },
    choice_build:function(item) {
      var choice, close_link;
      choice = Y.Node.create('<li class="search-choice"></li>').setContent('<span>'+ item.html +'</span>');
      if (item.disabled) {
        choice.addClass('search-choice-disabled');
      } else {
        close_link = Y.Node.create(Y.Lang.sub('<a href="{href}" class="{class}" rel="{rel}"></a>', {
          href: '#',
          class: 'search-choice-close',
          rel: item.array_index
        }));
        close_link.on('click', this.choice_destroy_link_click, this);
        choice.append(close_link);
      }
      return this.search_container.insert(choice,'before');
    },
    choice_destroy_link_click: function(evt) {
      evt.preventDefault();
      evt.stopPropagation();
      if (!this.is_disabled) {
        return this.choice_destroy(evt.target);
      }
    },
    choice_destroy: function(link) {
      if (this.result_deselect(link.getAttribute("rel"))) {
        this.show_search_field_default();
        if (this.is_multiple && this.choices_count() > 0 && this.search_field.get('value').length < 1) {
          this.results_hide();
        }
        link.ancestor('li').remove();
        return this.search_field_scale();
      }
    },
    results_reset: function() {
      this.form_field.options[0].selected = true;
      this.selected_option_count = null;
      this.single_set_selected_text();
      this.show_search_field_default();
      this.results_reset_cleanup();
      this.form_field_yui.simulate("change");
      if (this.active_field) {
        return this.results_hide();
      }  
    },
    results_reset_cleanup: function() {
      this.current_selectedIndex = this.form_field.selectedIndex;
      return this.selected_item.one("abbr").remove();
    },
    result_select: function(evt) {
      var high, high_id, item, position;
      if (this.result_highlight) {
        high = this.result_highlight;
        high_id = high.getAttribute("id");
        this.result_clear_highlight();
        if (this.is_multiple && this.max_selected_options <= this.choices_count()) {
          this.form_field_yui.fire("liszt:maxselected", {
            chosen: this
          }, this);
          return false;
        }
        if (this.is_multiple) {
          high.removeClass("active-result");
        } else {
          // if you are filtering results by typing, the previous selected result may or may not be there.
          if (this.search_results.one(".result-selected")) {
            this.search_results.one(".result-selected").removeClass("result-selected");
          }
          this.result_single_selected = high;
        }

        high.addClass("result-selected");
        position = high_id.substr(high_id.lastIndexOf("_") + 1);
        item = this.results_data[position];
        item.selected = true;
        this.form_field.options[item.options_index].selected = true;
        this.selected_option_count = null;
        if (this.is_multiple) {
          this.choice_build(item);
        } else {
          this.single_set_selected_text(item.text);
        }
        if (!((evt.metaKey || evt.ctrlKey) && this.is_multiple)) {
          this.results_hide();
        }
        this.search_field.set("value", "");
        this.search_field.set("placeholder",null);
        if (this.is_multiple || this.form_field.selectedIndex !== this.current_selectedIndex) {
          this.form_field_yui.simulate("change");
        }
        this.current_selectedIndex = this.form_field.selectedIndex;
        return this.search_field_scale();
      }
    },
    single_set_selected_text: function(text) {
      if (text == null) {
        text = this.default_text;
      }
      if (text === this.default_text) {
        this.selected_item.addClass("chzn-default");
      } else {
        this.single_deselect_control_build();
        this.selected_item.removeClass("chzn-default");
      }
      return this.selected_item.one("span").setContent(text);
    },
    result_deselect: function(pos) {
      var result, result_data;
      result_data = this.results_data[pos];
      if (!this.form_field.options[result_data.options_index].disabled) {
        result_data.selected = false;
        this.form_field.options[result_data.options_index].selected = false;
        this.selected_option_count = null;
        result = Y.one("#" + this.container_id + "_o_" + pos);
        result.removeClass("result-selected").addClass("active-result").show();
        this.result_clear_highlight();
        if (this.results_showing) {
          this.winnow_results();
        }
        /*
        NOTE: Removed this event to simulate an actual change for YUI. This enables your YUI Sandbox to listen on the
              select element itself for a change event.
          this.form_field_yui.fire("change", {
            deselected: this.form_field.options[result_data.options_index].value
          });
        */
        this.form_field_yui.simulate("change");
        this.search_field_scale();
        return true;
      } else {
        return false;
      }
    },
    single_deselect_control_build: function(){
      if (!this.allow_single_deselect) {
        return;
      }
      if (!this.selected_item.one("abbr")) {
        this.selected_item.one("span").insert("<abbr class=\"search-choice-close\"></abbr>", "after");
      }
      return this.selected_item.addClass("chzn-single-with-deselect");
    },
    get_search_text: function() {
      if (this.search_field.get('value') === this.default_text) {
        return "";
      } else {
        return this.search_field.get('value');
        /*
        NOTE: In the jQuery version, it creates a DIV#Element and then grabbed the text (".text()"). Not entirely
              sure on the purpose of this, but was just avoided by getting the value of the select box instead.
          return Y.Node.create('<div>'+this.search_field.get('value')+'</div>').get('outerHTML');
        */
      }
    },
    winnow_results_set_highlight: function() {
      var do_high, selected_results;
      selected_results = !this.is_multiple ? this.search_results.one(".result-selected.active-result") : null;
      do_high = selected_results ? selected_results : this.search_results.one(".active-result");
      if (do_high != null) {
        return this.result_do_highlight(do_high);
      }
    },
    no_results: function(terms) {
      var no_results_html;
      no_results_html = Y.Lang.sub('<li class="no-results">{text}<span>{terms}</span></li>', {text: this.results_none_found, terms: terms});
      return this.search_results.append(no_results_html);
    },
    no_results_clear: function() {
      return this.search_results.one(".no-results") ? this.search_results.one(".no-results").remove() : null;
    },
    keydown_arrow: function() {
      var next_sib;
      if (this.results_showing && this.result_highlight) {
        next_sib = this.result_highlight.next("li.active-result");
        if (next_sib) {
          return this.result_do_highlight(next_sib);
        }
      } else {
        return this.results_show();
      }
    },
    keyup_arrow: function() {
      var prev_sibs;
      if (!this.results_showing && !this.is_multiple) {
        return this.results_show();
      } else if (this.result_highlight) {
        prev_sibs = this.result_highlight.previous("li.active-result");
        if (prev_sibs) {
          return this.result_do_highlight(prev_sibs);
        } else {
          if (this.choices_count() > 0) {
            this.results_hide();
          }
          return this.result_clear_highlight();
        }
      }
    },
    keydown_backstroke: function() {
      var next_available_destroy;
      if (this.pending_backstroke) {
        this.choice_destroy(this.pending_backstroke.one("a"));
        return this.clear_backstroke();
      } else {
        next_available_destroy = this.search_container.all('li.search-choice').slice(-1).item(0);
        if (next_available_destroy && !next_available_destroy.hasClass("search-choice-disabled")) {
          this.pending_backstroke = next_available_destroy;
          if (this.single_backstroke_delete) {
            return this.keydown_backstroke();
          } else {
            return this.pending_backstroke.addClass("search-choice-focus");
          }
        }
      }
    },
    clear_backstroke: function() {
      if (this.pending_backstroke) {
        this.pending_backstroke.removeClass("search-choice-focus");
      }
      return this.pending_backstroke = null;
    },
    keydown_checker: function(evt) {
      var stroke, _ref1;
      stroke = (_ref1 = evt.which) != null ? _ref1 : evt.keyCode;
      this.search_field_scale();
      if (stroke !== 8 && this.pending_backstroke) {
        this.clear_backstroke();
      }
      switch (stroke) {
        case 8:
          this.backstroke_length = this.search_field.get('value').length;
          break;
        case 9:
          if (this.results_showing && !this.is_multiple) {
            this.result_select(evt);
          }
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
          evt.preventDefault();
          this.keydown_arrow();
          break;
      }
    },
    search_field_scale: function() {
      var div, h, style, style_block, styles, w, _i, _len;
      if (this.is_multiple) {
        h = 0;
        w = 0;
        style_block = "position:absolute; left: -1000px; top: -1000px; visibility:hidden;";
        styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'];
        for (_i = 0, _len = styles.length; _i < _len; _i++) {
          style = styles[_i];
          style_block += style + ":" + this.search_field.getStyle(style) + ";";
        }
        div = Y.Node.create('<div></div>').setAttribute('style', style_block);
        div.setContent( this.search_field.get('value') );
        Y.one('body').append(div);
        w = parseInt(div.get('region').width) + 25;
        div.remove();

        if (!this.f_width) {
          this.f_width = this.container.get('region').width;
        }
        if (w > this.f_width - 10) {
          w = this.f_width - 10;
        }
        return this.search_field.setStyles({
          'width': w + 'px'
        });
      }
    },
    generate_random_id: function() {
      return Y.guid();
    }
  });
  Y.Chosen = YUIChosen;
},'0.1.0',{requires:['node','node-event-simulate','event'], skinnable:false});