Events = {}

# W3C event model
if document.addEventListener?
  Events.add = (el, type, fn) ->
    # TODO: Support these emulated events in remove_event (need to store wrapper function to access it later)
    emulated_event = emulated_events[type]
    if emulated_event
      fn = emulated_event.handler(el, fn)
      type = emulated_event.mapped_to

    el.addEventListener(type, fn, false)
    
  Events.remove = (el, type, fn) -> el.removeEventListener(type, fn, false)

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

# mouseenter/mouseleave emulation for unsupported browsers
# Based off technique at http://blog.stchur.com/2007/03/15/mouseenter-and-mouseleave-events-for-firefox-and-other-non-ie-browsers/
emulated_events =
  mouseenter:
    mapped_to: 'mouseover'
    handler: (original_el, fn) ->
      (evt) ->
        # Don't fire if it's a child element (so it's not fired over and over again)
        # In this case, relatedTarget is the element the mouse has moved from. It is null in the case where the mouse
        # is moved from outside the browser window onto an element.
        return if original_el is evt.relatedTarget or (evt.relatedTarget? and DOM.find_parent evt.relatedTarget, (el) -> el is original_el)

        fn.call(this, evt)

emulated_events.mouseleave =
  mapped_to: 'mouseout',
  handler: emulated_events.mouseenter.handler