var config = {
  '.chosen-select'                 : {},
  '.chosen-select-deselect'        : { allow_single_deselect: true },
  '.chosen-select-no-single'       : { disable_search_threshold: 10 },
  '.chosen-select-no-results'      : { no_results_text: 'Oops, nothing found!' },
  '.chosen-select-rtl'             : { rtl: true },
  '.chosen-select-width'           : { width: '95%' },
  '.chosen-select-transliteration' : { normalize_search_text: transl, search_contains: true }
}
for (var selector in config) {
  $(selector).chosen(config[selector]);
}
