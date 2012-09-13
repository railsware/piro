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
    PiroBackground.updateProgress() if PiroBackground.updateState is true
  updateProgress: (progress = null) ->
    return false unless PiroBackground.popupEvents?
    progress = PiroBackground.updateStateProgress unless progress?
    PiroBackground.popupEvents.trigger "update:pivotal:progress", 
      progress: progress
  initAutoupdate: ->
    return false if PiroBackground.updateState is true
    PiroBackground.updateState = true
    PiroBackground.updateStateProgress = 0
    PiroBackground.checkUpdateState()
    PiroBackground.db.getAccounts
      success: (accounts) =>
        if accounts.length > 0
          PiroBackground.updateStatePerAccount = Math.round(100/accounts.length)
          PiroBackground.updateDataForAccount(account) for account in accounts
  updateDataForAccount: (account) ->
    PiroBackground.pivotalApi[account.id] = new PivotaltrackerApi(account)
    PiroBackground.pivotalApi[account.id].getProjects
      success: (data, textStatus, jqXHR) =>
        PiroBackground.aggregateAllStories(account, data)
  aggregateAllStories: (account, projects) ->
    projectsCount = projects.length
    if projectsCount > 0
      percentPerProject = Math.round(PiroBackground.updateStatePerAccount/projectsCount)
      for project in projects
        PiroBackground.pivotalApi[account.id].getStories project, 
          complete: =>
            PiroBackground.updateStateProgress += percentPerProject
            PiroBackground.updateProgress(PiroBackground.updateStateProgress)
            projectsCount--
            PiroBackground.saveAllData(account, projects) if projectsCount <= 0
          success: (project, stories, textStatus, jqXHR) =>
            _.extend(projects[_.indexOf(projects, project)], {stories_count: stories.length})
            PiroBackground.db.setStories(stories)
    else
      PiroBackground.updateStateProgress += PiroBackground.updateStatePerAccount
      PiroBackground.updateProgress(PiroBackground.updateStateProgress)
      PiroBackground.saveAllData(account, projects)
  saveAllData: (account, projects) ->
    PiroBackground.db.setProjects account, projects, 
      success: =>
        PiroBackground.cleanupData(account)
  cleanupData: (account) ->
    # clean stories, icons
    PiroBackground.db.getAllProjects
      success: (projects) =>
        projectIds = _.pluck(projects, 'id')
        PiroBackground.db.getStories
          success: (stories) =>
            PiroBackground.db.deleteStoryById(story.id) for story in stories when _.indexOf(projectIds, story.project_id) is -1
        PiroBackground.db.getProjectIcons
          success: (icons) =>
            PiroBackground.db.deleteProjectIcon(icon.id) for icon in icons when _.indexOf(projectIds, icon.id) is -1
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