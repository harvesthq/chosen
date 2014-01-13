custom_event_support = ->
  try
    new CustomEvent('CustomEvent')
  catch error
    return false
  return true

if not Element.prototype.matches then Element.prototype.matches = (selector) ->
  matches = this.webkitMatchesSelector or this.mozMatchesSelector or this.msMatchesSelector or this.oMatchesSelector
  return matches.call this, selector

Element.prototype.parents = (selector) ->
  parents = []
  p = this.parentNode
  while p not in [document, null]
    o = p
    parents.push o
    p = o.parentNode
  if selector
    parents = parents.filter (parent) ->
      parent.matches selector
  return parents

Element.prototype.closest = (selector) ->
  p = this
  while p isnt document and not p.matches selector
    p = p.parentNode
  return if p isnt document then p else null

if custom_event_support() then Element.prototype.trigger = (eventName, data) ->
  params = bubbles: false, cancelable: false, detail: data
  evt = if data? then (new CustomEvent eventName, params) else (new Event)
  this.dispatchEvent evt
else
  Element.prototype.trigger = (eventName, data) ->
    params = bubbles: false, cancelable: false, detail: data
    evt = document.createEvent 'CustomEvent'
    evt.initCustomEvent eventName, params.bubbles, params.cancelable, params.detail
    this.dispatchEvent evt

if not Element.prototype.remove
  Element.prototype.remove = ->
    if this and this.parentNode
      this.parentNode.removeChild this
    return

class ClassLists
  constructor: (nodelist) ->
    @nodelist = nodelist
  add: (className) ->
    @nodelist.forEach (node) ->
      node.classList.add className
  remove: (className) ->
    @nodelist.forEach (node) ->
      node.classList.remove className

class ClassListIE9
  constructor: (node) ->
    @node = node
  add: (className) ->
    idx = @node.className.indexOf className
    if idx is -1
      @node.className += ' ' + className
  remove: (className) ->
    idx = @node.className.indexOf className
    if idx isnt -1
      @node.className = @node.className.replace(className, '').replace('  ', ' ')
    return
  contains: (className) ->
    return if @node.className.indexOf(className) isnt -1 then true else false

if not window.DOMTokenList or not Element.prototype.classList
  Object.defineProperty Element.prototype, 'classList',
    get: ->
      this.classList = new ClassListIE9 this

Object.defineProperty Array.prototype, 'classList',
  get: ->
    this.classList = new ClassLists this

NodeList.prototype.toArray = ->
  return [].slice.call this

NodeList.prototype.forEach = Array.prototype.forEach

Object.defineProperty NodeList.prototype, 'classList',
  get: ->
    this.classList = new ClassLists this

Element.prototype.nextAll = (selector) ->
  s = this.parentNode.querySelectorAll(selector).toArray()
  idx = s.indexOf this
  return s[(idx + 1)..]

Element.prototype.prevAll = (selector) ->
  s = this.parentNode.querySelectorAll(selector).toArray().reverse()
  idx = s.indexOf this
  return s[(idx + 1)..]

Element.prototype.siblings = (selector) ->
  s = []
  el = this.nextElementSibling
  while el isnt null
    s.push el
    el = el.nextElementSibling
  el = this.previousElementSibling
  while el isnt null
    s.unshift el
    el = el.previousElementSibling
  if selector
    s = s.filter (elt) ->
      elt.matches selector
  return s

Element.prototype.before = (element) ->
  this.parentNode.insertBefore element, this
  return this

Element.prototype.after = (element) ->
  this.parentNode.insertBefore element, this.nextElementSibling
  return this