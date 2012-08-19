root = global ? window

root.PopupRedirect = 
  init: ->
    indexUrl = chrome.extension.getURL('index.html')
    chrome.tabs.query {}, (tabs) ->
      for tab in tabs
        if tab.url.substring(0, indexUrl.length) == indexUrl
          chrome.tabs.update tab.id, {active: true}
          window.close()
          return false
      chrome.tabs.create {url: indexUrl, active: true}, (tab) ->
        chrome.tabs.update tab.id, {active: true}
        window.close()
        return false
$ ->
  PopupRedirect.init()