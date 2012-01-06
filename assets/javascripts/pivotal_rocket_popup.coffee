root = global ? window

root.PivotalRocketPopup =
  background_page: chrome.extension.getBackgroundPage()
  # init popup view
  init: ->
    PivotalRocketPopup.background_page.PivotalRocketBackground.popup = root
    PivotalRocketPopup.background_page.PivotalRocketBackground.init_popup()
    
$ ->
  PivotalRocketPopup.init()