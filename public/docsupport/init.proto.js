document.observe('dom:loaded', function(evt) {
  var config = {
    '.chosen-select'           : {},
    '.chosen-select-deselect'  : { allow_single_deselect: true },
    '.chosen-select-no-single' : { disable_search_threshold: 10 },
    '.chosen-select-no-results': { no_results_text: 'Oops, nothing found!' },
    '.chosen-select-rtl'       : { rtl: true },
    '.chosen-select-width'     : { width: '95%' }
  }
  
  for (var selector in config) {
    $$(selector).each(function(element) {
      new Chosen(element, config[selector]);
    });
  }
});


var sb_chosens = [];
function set_search_behaviour() {
    var options = {};
    $$("[data-search-behaviour]").each(function(elm){
        var setting = elm.readAttribute('data-search-behaviour');
        options[setting] = $$('[name=' + elm.name + ']:checked')[0].value;
        var stringified = false;
        if (options[setting] === 'true') {
            options[setting] = true;
        } else if (options[setting] === 'false') {
            options[setting] = false;
        } else if (options[setting] === 'regex_space') {
            options[setting] = /\s/;
        } else {
            stringified = JSON.stringify(options[setting]);
        }
        code_elm = elm.up('div').down('> label > code');
        code_elm.update(setting + ': ' + (stringified ? stringified : options[setting].toString()));
        Prism.highlightElement(code_elm);
    });
    sb_chosens.each(function(elm) {
        elm.destroy();
    });
    sb_chosens = [];
    $$('.chosen-select-sb').each(function(elm){
        sb_chosens.push(new Chosen(elm, options));
    });
}
document.on('change', "[data-search-behaviour]", set_search_behaviour);

set_search_behaviour();