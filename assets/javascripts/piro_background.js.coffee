root = global ? window

root.PiroBackground = 
  init: ->
    console.log "back"
# init
$ ->
  PiroBackground.init()