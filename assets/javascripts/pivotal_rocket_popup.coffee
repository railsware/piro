root = global ? window

root.PivotalRocketPopup =
  background_page: chrome.extension.getBackgroundPage()
  # init popup view
  init: ->
    if PivotalRocketPopup.check_working_mode()
      PivotalRocketPopup.background_page.PivotalRocketBackground.popup = root
      PivotalRocketPopup.background_page.PivotalRocketBackground.init_popup()
      PivotalRocketPopup.init_listener()
  # check fullscreen/popup mode
  check_working_mode: ->
    popup_url = chrome.extension.getURL('popup.html')
    # fullscreen
    if PivotalRocketStorage.get_fullscreen_mode()
      if document.location.search == '?popup'
        $('body').css
          width: 0
          height: 0
          display: 'none'
        chrome.tabs.query {}, (tabs) ->
          for tab in tabs
            if tab.url.substring(0, popup_url.length) == popup_url
              chrome.tabs.update tab.id, {active: true}
              window.close()
              return false
          chrome.tabs.create {url: popup_url, active: true}, (tab) ->
            window.close()
            return false
        window.close()
        return false
      $('body').addClass('fullscreen')
    #popup
    else
      if document.location.search != '?popup'
        chrome.tabs.query {active: true}, (tabs) ->
          for tab in tabs
            if document.location.href.substring(0, popup_url.length) == popup_url
              chrome.tabs.remove(tab.id)
        window.close()
        return false
    return true
  # init listener
  init_listener: ->
    chrome.extension.onRequest.addListener (request, sender, sendResponse) ->
      if request.clippy_for_story?
        PivotalRocketPopup.init_clippy_for_story(request.clippy_for_story)
        sendResponse({})
  # init clippy for story view
  init_clippy_for_story: (story_data) ->
    width = 51
    height = 15
    params = 
      allowScriptAccess: 'always'
      wmode: 'opaque'
      scale: 'noscale'
      quality: 'high'
      width: width
      height: height
      bgcolor: "#EEEEEE"
    if $("#clippyStory#{story_data.id}").length > 0  
      swfobject.embedSWF('images/clippy/clippy_attachment.swf', 
      "clippyStory#{story_data.id}", width, height, '9.0.0', 
      'javascripts/vendors/swfobject/expressInstall.swf', 
      {text: story_data.id}, params, {})
    if $("#clippyUrl#{story_data.id}").length > 0  
      swfobject.embedSWF('images/clippy/clippy_attachment.swf', 
      "clippyUrl#{story_data.id}", width, height, '9.0.0', 
      'javascripts/vendors/swfobject/expressInstall.swf', 
      {text: story_data.url}, params, {})
    if $('div.attachment_clippy').length > 0
      $('div.attachment_clippy').each (index) ->
        url = $(this).data('attachmentUrl')
        attachment_id = $(this).attr('id')
        swfobject.embedSWF('images/clippy/clippy_attachment.swf', 
        attachment_id, width, height, '9.0.0', 
        'javascripts/vendors/swfobject/expressInstall.swf', 
        {text:url}, params, {})
    
$ ->
  PivotalRocketPopup.init()