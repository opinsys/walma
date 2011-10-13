$ = jQuery

$.support.touch = ('ontouchstart' of window)

touch = {}

parentIfText = (node) ->
  if 'tagName' of node then node else node.parentNode

swipeDirection = (x1, x2, y1, y2) ->
  xDelta = Math.abs(x1 - x2)
  yDelta = Math.abs(y1 - y2)

  if xDelta >= yDelta
    if x1 - x2 > 0 then 'Left' else 'Right'
  else
    if y1 - y2 > 0 then 'Up' else 'Down'

$ ->
  $('body').bind 'touchstart', (e) ->
    e     = e.originalEvent
    now   = Date.now()
    delta = now - (touch.last or now)
    touch.target = parentIfText(e.touches[0].target)
    touch.x1 = e.touches[0].pageX
    touch.y1 = e.touches[0].pageY
    touch.last = now

  .bind 'touchmove', (e) ->
    e = e.originalEvent
    touch.x2 = e.touches[0].pageX
    touch.y2 = e.touches[0].pageY

  .bind 'touchend', (e) ->
    e = e.originalEvent
    if touch.x2 > 0 or touch.y2 > 0
      (Math.abs(touch.x1 - touch.x2) > 30 or Math.abs(touch.y1 - touch.y2) > 30) and
        $(touch.target).trigger('swipe') and
        $(touch.target).trigger('swipe' + (swipeDirection(touch.x1, touch.x2, touch.y1, touch.y2)))
      touch.x1 = touch.x2 = touch.y1 = touch.y2 = touch.last = 0
    else if 'last' of touch
      $(touch.target).trigger('tap')
      touch = {}

  .bind 'touchcancel', (e) ->
    touch = {}

if $.support.touch
  $('body').bind 'click', (e) ->
    e.preventDefault()
else
  $ ->
    $('body').bind 'click', (e) ->
      $(e.target).trigger('tap')

types = ['swipe',
         'swipeLeft',
         'swipeRight',
         'swipeUp',
         'swipeDown',
         'tap']
for m in types
  do (m) ->
    $.fn[m] = (callback) ->
      this.bind(m, callback)
