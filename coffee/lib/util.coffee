Util =
  camel_case: (string) -> string.replace /-([a-z])/g, (match) -> match[1].toUpperCase()
  
# Check for native String.trim
if String::trim?
  Util.trim = (string) -> string.trim()
else
  Util.trim = (string) -> string.replace /^\s+|\s+$/g, ''