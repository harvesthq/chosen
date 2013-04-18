engine = null
if window.navigator.appName == "Microsoft Internet Explorer"
  if document.documentMode # IE8 or later
    engine = document.documentMode
  else # IE 5-7
    engine = 5 # Assume quirks mode unless proven otherwise
    engine = 7 if document.compatMode and document.compatMode == "CSS1Compat" # standards mode

    # There is no test for IE6 standards mode because that mode was replaced by IE7 standards mode; there is no emulation.

Chosen.IE_DOCUMENT_MODE = engine
