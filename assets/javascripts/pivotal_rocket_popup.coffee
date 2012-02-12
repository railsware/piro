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
      if request.clippy_for_story?
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
      width: width
      height: height
      bgcolor: "#000"
    if $("#clippyStory#{story_data.id}").length > 0  
      swfobject.embedSWF('images/clippy/clippy.swf', 
      "clippyStory#{story_data.id}", width, height, '9.0.0', 
      'javascripts/vendors/swfobject/expressInstall.swf', 
      {text: story_data.id}, params, {})
    if $("#clippyUrl#{story_data.id}").length > 0  
      swfobject.embedSWF('images/clippy/clippy.swf', 
      "clippyUrl#{story_data.id}", width, height, '9.0.0', 
      'javascripts/vendors/swfobject/expressInstall.swf', 
      {text: story_data.url}, params, {})
    if $('div.attachment_clippy').length > 0
      $('div.attachment_clippy').each (index) ->
        url = $(this).data('attachmentUrl')
        attachment_id = $(this).attr('id')
        swfobject.embedSWF('images/clippy/clippy_attachment.swf', 
        attachment_id, height, height, '9.0.0', 
        'javascripts/vendors/swfobject/expressInstall.swf', 
        {text:url}, params, {})
    
$ ->
  PivotalRocketPopup.init()