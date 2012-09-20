root = global ? window

root.PiroContentScripts = 
  init: ->
    return false unless root.localStorage.getItem("test_key") is true
    console.log "Test"

# init
root.onload = root.PiroContentScripts.init