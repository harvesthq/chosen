
__hasProp = {}.hasOwnProperty;
__extends = function(child, parent) {
  for (var key in parent) {
    if (__hasProp.call(parent, key)) child[key] = parent[key];
  }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor();
  child.__super__ = parent.prototype;
  return child;
};

describe('AbstractChosen', function(){

  var chosen, options, data, TestChosen, formField;

  beforeEach(function() {
    TestChosen = function() {
      TestChosen.__super__.constructor.apply(this, arguments);
    }

    __extends(TestChosen, AbstractChosen);

    TestChosen.prototype.setup = function() {};
    TestChosen.prototype.set_up_html = function() {};
    TestChosen.prototype.register_observers = function() {};
    TestChosen.prototype.no_results_clear = function() {};
    TestChosen.prototype.result_clear_highlight = function() {};
    TestChosen.prototype.update_results_content = function() {};
    TestChosen.prototype.winnow_results_set_highlight = function() {};

    TestChosen.prototype.get_search_text = jasmine.createSpy("Get search text");


    formField = {
      getAttribute: function(){}
    }
  });

  describe('winnowing results', function(){
    describe('given a search with a hyphen', function() {
      beforeEach(function(){
        TestChosen.prototype.get_search_text.andCallFake(function() {
          return 'James-Gabe';
        });
      });

      describe('without character substitution', function() {
        beforeEach(function() {
          options = { };
          data = [
            { html: 'James-Gabe' },
            { html: 'James Gabe' },
            { html: 'JamesGabe' }
          ];
          chosen = new TestChosen(formField, options);
          chosen.results_data = data
        });
        it('should match "James-Gabe"', function() {
          chosen.winnow_results()
          expect(data[0].search_match).toBeTruthy();
          expect(data[1].search_match).toBeFalsy();
          expect(data[2].search_match).toBeFalsy();
        });
      });
      describe('with character substitution', function() {
        beforeEach(function() {
          TestChosen.prototype.get_search_text.andCallFake(function() {
            return 'JamesGabe';
          });
          options = {
            ignore_regexp: /[\s\-]/
          };
          data = [
            { html: 'James-Gabe' },
            { html: 'James Gabe' },
            { html: 'JamesGabe' }
          ];
          chosen = new TestChosen(formField, options);
          chosen.results_data = data
        });
        it('should match "James-Gabe", "James Gabe" and "JamesGabe"', function() {
          chosen.winnow_results()
          expect(data[0].search_match).toBeTruthy();
          expect(data[1].search_match).toBeTruthy();
          expect(data[2].search_match).toBeTruthy();
        });
      });
    });
  });
});

