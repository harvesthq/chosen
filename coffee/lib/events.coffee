Events = {}

# W3C event model
if document.addEventListener?
  Events.add = (el, type, fn) ->
    # If this event is an emulated one, we need to get the wrapper for it
    if is_emulated_event type
      fn = wrap_emulated_event el, type, fn
      type = emulated_event_mapped_to type

    el.addEventListener(type, fn, false)
    
  Events.remove = (el, type, fn) ->
    # If this event is an emulated one, we need to remove the wrapper function, not the raw function passed in
    if is_emulated_event type
      fn = unwrap_emulated_event el, type, fn
      type = emulated_event_mapped_to type
      
    el.removeEventListener(type, fn, false)

# Legacy IE event model
# Based off https://github.com/Daniel15/JSFramework/blob/master/events.js and http://ejohn.org/projects/flexible-javascript-events/
else if document.attachEvent?
  Events.add = (el, type, fn) ->
    # Create a wrapper that normalises some properties in IE
    # Save it in case we want to remove the handler later
    handler = el['eventhandler' + type + fn] = ->
      evt = window.event
      # Normalize the event
      # target - What actually triggered the event
      evt.target = evt.srcElement
      # currentTarget - Where the event has bubbled up to (always the object the handler is attached to)
      # Reference: https://developer.mozilla.org/en/DOM/event.currentTarget
      evt.currentTarget = el
      # Shim for preventDefault
      evt.preventDefault = -> evt.returnValue = false

      fn.call(el, evt)

    el.attachEvent('on' + type, handler)

  Events.remove = (el, type, fn) ->
    # Find the wrapper function that was created when the event was added
    handler = el['eventhandler' + type + fn]
    el.detachEvent('on' + type, handler)
    el['eventhandler' + type + fn] = nul

# TODO: The createEvent method is deprecated. Use event constructors instead. - https://developer.mozilla.org/en-US/docs/Web/API/document.createEvent
# W3C event model
if document.createEvent?
  Events.fire = (el, type, memo = {}) ->
    event = document.createEvent "HTMLEvents"
    event.initEvent type, true, true
    event.eventName = type
    event.memo = memo
    el.dispatchEvent event

  # Legacy IE event model
else if document.createEventObject?
  Events.fire = (el, type, memo = {}) ->
    # FIXME legacy IE doesn't support firing custom events - Just ignore them for now.
    return if type.indexOf(':') > -1

    event = document.createEventObject()
    event.eventType = type
    event.eventName = type
    event.memo = memo
    el.fireEvent "on#{type}", event
    
###############################################################################
# Event emulation

# Check if an event should be emulated
is_emulated_event = (type) -> emulated_events[type]?
  
# Check which native event the specified emulated event should map to
emulated_event_mapped_to = (type) -> emulated_events[type].mapped_to

# Wrap an emulated event in a native event  
wrap_emulated_event = (el, type, fn) ->
  wrapped_fn_key = "#{DOM.unique_id el}_#{type}_#{fn}"

  # If this function hasn't been wrapped yet, wrap it now
  if not wrap_emulated_event.cache[wrapped_fn_key]?
    wrap_emulated_event.cache[wrapped_fn_key] = emulated_events[type].handler(el, fn)

  return wrap_emulated_event.cache[wrapped_fn_key] 

# Cache of wrapped events
wrap_emulated_event.cache = {}

# Return the wrapped emulated event (as per `wrap_emulated_event`), then delete the wrapper from the cache
unwrap_emulated_event = (el, type, fn) ->
  wrapped_fn_key = "#{DOM.unique_id el}_#{type}_#{fn}"
  wrapped_fn = wrap_emulated_event el, type, fn
  
  wrap_emulated_event.cache[wrapped_fn_key] = null
  return wrapped_fn
  
# A hash of events that should be emulated
emulated_events =
  mouseenter:
    mapped_to: 'mouseover'
    handler: (original_el, fn) ->
      (evt) ->
        # mouseenter/mouseleave emulation for unsupported browsers
        # Based off technique at http://blog.stchur.com/2007/03/15/mouseenter-and-mouseleave-events-for-firefox-and-other-non-ie-browsers/
        # Don't fire if it's a child element (so it's not fired over and over again)
        # In this case, relatedTarget is the element the mouse has moved from. It is null in the case where the mouse
        # is moved from outside the browser window onto an element.
        return if original_el is evt.relatedTarget or (evt.relatedTarget? and DOM.find_parent evt.relatedTarget, (el) -> el is original_el)

        fn.call(this, evt)

# mouseleave can use the same logic as mouseenter
emulated_events.mouseleave =
  mapped_to: 'mouseout',
  handler: emulated_events.mouseenter.handler