
$ ->
  buttons = $("form input[type='submit']")

  buttons.bind "tap", ->
    $(this).click()

