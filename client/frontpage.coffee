
$ ->
  $(".new-room input.go").bind "click", (e) ->
    e.preventDefault()
    window.location = $(".new-room input.room").val()
