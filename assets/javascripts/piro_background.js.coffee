root = global ? window

root.PiroBackground = 
  pivotalApi: null
  db: null
  popupEvents: null
  updateState: false
  pivotalAccounts: []
  pivotalAccountIterator: 0
  updateStateProgress: 0
  updateStatePerAccount: 0
  projectsData: null
  projectsCounter: 0
  percentPerProject: 0
  alarmName: "pivotalDataUpdate"
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
    chrome.alarms.onAlarm.addListener(PiroBackground.initDataPeriodicUpdate)
    PiroBackground.startDataUpdate()
  initDataPeriodicUpdate: (alarm) ->
    switch alarm.name
      when PiroBackground.alarmName
        PiroBackground.startDataUpdate()
      else
        # nothing
  startDataUpdate: ->
    return false if PiroBackground.updateState is true
    PiroBackground.projectsData = null
    PiroBackground.updateState = true
    PiroBackground.updateStateProgress = 0
    PiroBackground.checkUpdateState()
    PiroBackground.db.getAccounts
      success: (accounts) =>
        if accounts.length > 0
          PiroBackground.pivotalAccounts = accounts
          PiroBackground.pivotalAccountIterator = 0
          PiroBackground.updateStatePerAccount = Math.ceil(100/PiroBackground.pivotalAccounts.length)
          PiroBackground.updateDataForAccount()
  updateDataForAccount: ->
    PiroBackground.pivotalApi = new PivotaltrackerApi(PiroBackground.pivotalAccounts[PiroBackground.pivotalAccountIterator])
    PiroBackground.pivotalApi.getProjects
      success: (data, textStatus, jqXHR) =>
        PiroBackground.aggregateAllStories(data)
  aggregateAllStories: (projects) ->
    PiroBackground.projectsData = projects
    PiroBackground.projectsCounter = 0
    if PiroBackground.projectsData.length > 0
      PiroBackground.percentPerProject = Math.ceil(PiroBackground.updateStatePerAccount/PiroBackground.projectsData.length)
      PiroBackground.fetchStoriesForProject()
    else
      PiroBackground.updateStateProgress += PiroBackground.updateStatePerAccount
      PiroBackground.updateProgress()
      PiroBackground.saveAllData()
  fetchStoriesForProject: ->
    PiroBackground.pivotalApi.getStories PiroBackground.projectsData[PiroBackground.projectsCounter], 
      complete: =>
        PiroBackground.updateStateProgress += PiroBackground.percentPerProject
        PiroBackground.updateProgress()
        if PiroBackground.projectsCounter + 1 >= PiroBackground.projectsData.length
          PiroBackground.saveAllData()
        else
          PiroBackground.projectsCounter += 1
          PiroBackground.fetchStoriesForProject()
      success: (project, stories, textStatus, jqXHR) =>
        _.extend(PiroBackground.projectsData[_.indexOf(PiroBackground.projectsData, project)], {stories_count: stories.length})
        PiroBackground.db.setStories(stories)
  saveAllData: ->
    PiroBackground.db.setProjects PiroBackground.pivotalAccounts[PiroBackground.pivotalAccountIterator], PiroBackground.projectsData, 
      success: =>
        if PiroBackground.pivotalAccountIterator + 1 < PiroBackground.pivotalAccounts.length
          PiroBackground.pivotalAccountIterator += 1
          PiroBackground.updateDataForAccount(PiroBackground.pivotalAccounts[PiroBackground.pivotalAccountIterator])
        else
          PiroBackground.cleanupData()
  cleanupData: ->
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
    chrome.alarms.create(PiroBackground.alarmName, {'delayInMinutes': PiroBackground.db.getUpdateIntervalLS()})
  # OMNIBOX  
  initOmnibox: ->
    return false unless chrome.omnibox?
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