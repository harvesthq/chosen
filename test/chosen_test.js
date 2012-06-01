/*global QUnit:false, module:false, test:false, asyncTest:false, expect:false*/
/*global start:false, stop:false ok:false, equal:false, notEqual:false, deepEqual:false*/
/*global notDeepEqual:false, strictEqual:false, notStrictEqual:false, raises:false*/
(function($) {

  /*
    ======== A Handy Little QUnit Reference ========
    http://docs.jquery.com/QUnit

    Test methods:
      expect(numAssertions)
      stop(increment)
      start(decrement)
    Test assertions:
      ok(value, [message])
      equal(actual, expected, [message])
      notEqual(actual, expected, [message])
      deepEqual(actual, expected, [message])
      notDeepEqual(actual, expected, [message])
      strictEqual(actual, expected, [message])
      notStrictEqual(actual, expected, [message])
      raises(block, [expected], [message])
  */

  module('Chosen smoke tests', {
    setup: function() {
    }
  });

  test('Chosen is on the jQuery prototype object', 1, function() {
    ok($.prototype.chosen, "The chosen function is truthy");
  });
  
  test('Apply Chosen', 3, function() {
    $("#test1").chosen();
    ok($("#test1_chzn").length, "Chosen has been applied to a select");
    equal($("#test1_chzn .chzn-results li").length, $("#test1 option").length, "Number of options matches.")
    ok($("#test1_chzn .chzn-drop").attr("style").match(/-9000/).length, "Dropdown is off screen")
  });

}(jQuery));
