root = global ? window

root.PivotalRocketOptions =
  background_page: chrome.extension.getBackgroundPage()
  
  init: ->
    console.debug PivotalRocketStorage.get_accounts()
    
$ ->
  PivotalRocketOptions.init()