root = global ? window

root.PiroOptions = 
  init: ->
    console.log "options"
# init
$ ->
  PiroOptions.init()