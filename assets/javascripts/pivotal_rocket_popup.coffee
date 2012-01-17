root = global ? window

root.PivotalRocketPopup =
  background_page: chrome.extension.getBackgroundPage()
  # init popup view
  init: ->
    PivotalRocketPopup.background_page.PivotalRocketBackground.popup = root
    PivotalRocketPopup.background_page.PivotalRocketBackground.init_popup()
    PivotalRocketPopup.init_listener()
  # init listener
  init_listener: ->
    chrome.extension.onRequest.addListener (request, sender, sendResponse) ->
      if !sender.tab? && request.clippy_for_story?
        PivotalRocketPopup.init_clippy_for_story(request.clippy_for_story)
        sendResponse({})
  # init clippy for story view
  init_clippy_for_story: (story_data) ->
    width = 110
    height = 15
    params = 
      allowScriptAccess: 'always'
      wmode: 'opaque'
      scale: 'noscale'
      quality: 'high'
      width: 110
      height: 15
      bgcolor: "#000"
      
    swfobject.embedSWF('images/clippy/clippy.swf', 
    "clippyStory#{story_data.id}", width, height, '9.0.0', 
    'javascripts/vendors/swfobject/expressInstall.swf', 
    {text: story_data.id}, params, {})
    swfobject.embedSWF('images/clippy/clippy.swf', 
    "clippyUrl#{story_data.id}", width, height, '9.0.0', 
    'javascripts/vendors/swfobject/expressInstall.swf', 
    {text: story_data.url}, params, {})
    
$ ->
  PivotalRocketPopup.init()