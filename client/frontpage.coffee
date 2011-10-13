
$ ->

  $(".new-room input.go").bind "tap", (e) ->
    e.preventDefault()
    window.location = $(".new-room input.room").val().replace /[^a-zA-Z0-9]/g, ""

