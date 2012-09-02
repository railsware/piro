root = global ? window

root.PiroBackground = 
  pivotalApi: null
  db: null
  popupEvents: null
  projectsData: null
  init: ->
    PiroBackground.db = new PiroStorage
      success: ->
        PiroBackground.initAutoupdate()
        PiroBackground.initOmnibox()
  initPopupView: (events) ->
    PiroBackground.popupEvents = events
  initAutoupdate: ->
    PiroBackground.db.getAccounts
      success: (accounts) =>
        PiroBackground.updateDataForAccount(accounts[0]) if accounts.length > 0
    #PiroBackground.popupEvents.trigger "updated:data", {} if PiroBackground.popupEvents?
  updateDataForAccount: (account) ->
    PiroBackground.pivotalApi = new PivotaltrackerApi(account)
    PiroBackground.pivotalApi.getProjects
      success: (data, textStatus, jqXHR) =>
        PiroBackground.aggregateAllStories(account, data)
  aggregateAllStories: (account, projects) ->
    projectsCount = projects.length
    for project in projects
      PiroBackground.pivotalApi.getStories project, 
        complete: =>
          projectsCount--
          PiroBackground.saveAllData(account, projects) if projectsCount <= 0
        success: (project, stories, textStatus, jqXHR) =>
          _.extend(projects[_.indexOf(projects, project)], {stories_count: stories.length})
          PiroBackground.db.setStories(stories)
  saveAllData: (account, projects) ->
    PiroBackground.db.setProjects account, projects, 
      success: =>
        PiroBackground.cleanupData(account)
  cleanupData: (account) ->
    # clean stories, icons
    console.log "comming soon..."
  # OMNIBOX  
  initOmnibox: ->
    chrome.omnibox.onInputCancelled.addListener ->
      PiroBackground.defaultOmniboxSuggestion()
    chrome.omnibox.onInputStarted.addListener ->
      PiroBackground.setOmniboxSuggestion('')
    chrome.omnibox.onInputChanged.addListener (text, suggest) ->
      PiroBackground.setOmniboxSuggestion(text)
    chrome.omnibox.onInputEntered.addListener (text) ->
      command = text.split(" ")
      indexUrl = chrome.extension.getURL('index.html')
      switch command[0]
        when "s"
          mainUrl = "#{indexUrl}#story/#{command[1]}" if command[1]?
        else
          mainUrl = "#{indexUrl}#story/#{command[0]}" if command[0]?
      chrome.tabs.query {active: true}, (tabs) ->
        for tab in tabs
          chrome.tabs.update tab.id, 
            url: mainUrl
  # default omnibox text
  defaultOmniboxSuggestion: ->
    chrome.omnibox.setDefaultSuggestion
      description: '<url><match>piro:</match></url> Go by PivotalTracker ID'
  # default omnibox text
  setOmniboxSuggestion: (text) ->
    defDescr = "<match><url>piro</url></match> "
    defDescr += if text.length > 0 then "<match>#{text}</match>" else "pivotal story id"
    chrome.omnibox.setDefaultSuggestion
      description: defDescr
# init
$ ->
  PiroBackground.init()