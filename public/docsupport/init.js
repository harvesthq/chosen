var config = {
  '.chosen-select'           : {},
  '.chosen-select-deselect'  : { allow_single_deselect: true },
  '.chosen-select-no-single' : { disable_search_threshold: 10 },
  '.chosen-select-no-results': { no_results_text: 'Oops, nothing found!' },
  '.chosen-select-rtl'       : { rtl: true },
  '.chosen-select-width'     : { width: '95%' }
}
for (var selector in config) {
  $(selector).chosen(config[selector]);
}

function set_search_behaviour() {
    var options = {};
    $("[data-search-behaviour]").each(function(){
        var setting = $(this).data('search-behaviour');
        options[setting] = $('[name=' + this.name + ']:checked').val();
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
        code_elm = $(this).closest('div').find('> label > code');
        code_elm.html(setting + ': ' + (stringified ? stringified : options[setting].toString()));
        Prism.highlightElement(code_elm[0]);
    });
    
    $('.chosen-select-sb').chosen("destroy").chosen(options);
}
$(document).on('change', "[data-search-behaviour]", set_search_behaviour);

set_search_behaviour();