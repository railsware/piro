root = global ? window

root.PiroBackground = 
  pivotalApi: {}
  db: null
  popupEvents: null
  projectsData: null
  updateState: false
  updateStateProgress: 0
  updateStatePerAccount: 0
  init: ->
    PiroBackground.db = new PiroStorage
      success: ->
        PiroBackground.initAutoupdate()
        PiroBackground.initOmnibox()
  initPopupView: (events) ->
    PiroBackground.popupEvents = events
    PiroBackground.checkUpdateState()
  checkUpdateState: ->
    return false unless PiroBackground.popupEvents?
    PiroBackground.popupEvents.trigger "update:pivotal:data", 
      updateState: PiroBackground.updateState
  updateProgress: ->
    return false unless PiroBackground.popupEvents?
    PiroBackground.popupEvents.trigger "update:pivotal:progress", 
      progress: PiroBackground.updateStateProgress
  initAutoupdate: ->
    return false if PiroBackground.updateState is true
    PiroBackground.updateState = true
    PiroBackground.checkUpdateState()
    PiroBackground.db.getAccounts
      success: (accounts) =>
        if accounts.length > 0
          PiroBackground.updateStateProgress = 0
          PiroBackground.updateStatePerAccount = Math.round(100/accounts.length)
          PiroBackground.updateDataForAccount(account) for account in accounts
  updateDataForAccount: (account) ->
    PiroBackground.pivotalApi[account.id] = new PivotaltrackerApi(account)
    PiroBackground.pivotalApi[account.id].getProjects
      success: (data, textStatus, jqXHR) =>
        PiroBackground.aggregateAllStories(account, data)
  aggregateAllStories: (account, projects) ->
    projectsCount = projects.length
    percentPerProject = Math.round(PiroBackground.updateStatePerAccount/projectsCount)
    for project in projects
      PiroBackground.pivotalApi[account.id].getStories project, 
        complete: =>
          PiroBackground.updateStateProgress += percentPerProject
          PiroBackground.updateProgress()
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
    PiroBackground.updateFinished()
  updateFinished: ->
    PiroBackground.updateState = false
    PiroBackground.checkUpdateState()

  # OMNIBOX  
  initOmnibox: ->
    chrome.omnibox.onInputCancelled.addListener ->
      PiroBackground.defaultOmniboxSuggestion()
    chrome.omnibox.onInputStarted.addListener ->
      PiroBackground.setOmniboxSuggestion('')
    chrome.omnibox.onInputChanged.addListener (text, suggest) ->
      PiroBackground.setOmniboxSuggestion(text)
    chrome.omnibox.onInputEntered.addListener (text) ->
      PiroBackground.enterOmniboxData(text)
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
  enterOmniboxData: (text) ->
    command = text.split(" ")
    indexUrl = chrome.extension.getURL('index.html')
    switch command[0]
      when "s"
        mainUrl = "#{indexUrl}#story/#{command[1]}" if command[1]?
      else
        mainUrl = "#{indexUrl}#story/#{command[0]}" if command[0]?
    chrome.tabs.query {}, (tabs) ->
      chrome.tabs.remove(tab.id) for tab in tabs when tab.url.substring(0, indexUrl.length) is indexUrl
    chrome.tabs.query {active: true}, (tabs) ->
      for tab in tabs
        chrome.tabs.update tab.id, 
          url: mainUrl
# init
$ ->
  PiroBackground.init()