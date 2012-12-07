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
  storiesIds: []
  percentPerProject: 0
  alarmName: "pivotalDataUpdate"
  # omnibox search stories
  omniboxStories: []
  init: ->
    PiroBackground._storiesForOmnibox()
    PiroBackground.initAutoupdate()
    PiroBackground.initContextMenu()
  initListeners: ->
    chrome.contextMenus.onClicked.addListener(PiroBackground.clickContextMenu) unless chrome.contextMenus.onClicked.hasListener(PiroBackground.clickContextMenu)
    chrome.alarms.onAlarm.addListener(PiroBackground.initDataPeriodicUpdate) unless chrome.alarms.onAlarm.hasListener(PiroBackground.initDataPeriodicUpdate)
    PiroBackground.setAlarm()
    PiroBackground.initOmniboxListeners()
  setAlarm: ->
    if PiroBackground.db?
      PiroBackground._initAlarm()
    else
      PiroBackground.db = new PiroStorage
        success: ->
          PiroBackground._initAlarm()
  _initAlarm: ->
    chrome.alarms.create(PiroBackground.alarmName, {'delayInMinutes': PiroBackground.db.getUpdateIntervalLS()})
  initPopupView: (events) ->
    PiroBackground.popupEvents = events
    PiroBackground.checkUpdateState()
  checkUpdateState: ->
    PiroBackground.updateBadgeText()
    if PiroBackground.popupEvents? and PiroBackground.popupEvents.trigger?
      PiroBackground.popupEvents.trigger "update:pivotal:data",
        updateState: PiroBackground.updateState
      PiroBackground.updateProgress() if PiroBackground.updateState is true
    else
      chrome.extension.sendMessage {type: "update:pivotal:data"}, (response) ->
        PiroBackground.initPopupView(response.events) if response? && response.events?
  updateProgress: ->
    PiroBackground.updateBadgeText()
    return false if !PiroBackground.popupEvents? or !PiroBackground.popupEvents.trigger?
    progress = PiroBackground.updateStateProgress
    progress = 100 if progress > 100
    PiroBackground.popupEvents.trigger "update:pivotal:progress",
      progress: progress
  updateBadgeText: (params = {}) ->
    if PiroBackground.updateState is true
      percent = PiroBackground.updateStateProgress
      percent = 0 unless percent?
      percent = 100 if percent > 100
      chrome.browserAction.setBadgeText({'text': "#{percent}"})
      chrome.browserAction.setBadgeBackgroundColor({'color': "#666666"})
    else
      chrome.browserAction.setBadgeText({'text': ''})
      chrome.browserAction.setBadgeBackgroundColor({'color': "#FF0000"})
  initAutoupdate: ->
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
    PiroBackground.storiesIds = []
    PiroBackground.updateState = true
    PiroBackground.updateStateProgress = 0
    PiroBackground.checkUpdateState()
    PiroBackground.db = new PiroStorage
      success: ->
        PiroBackground.db.getAccounts
          success: (accounts) =>
            if accounts.length > 0
              PiroBackground.pivotalAccounts = accounts
              PiroBackground.pivotalAccountIterator = 0
              PiroBackground.updateStatePerAccount = Math.ceil(100/PiroBackground.pivotalAccounts.length)
              PiroBackground.updateDataForAccount()
            else
              PiroBackground.updateState = false
              PiroBackground.checkUpdateState()
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
        PiroBackground.storiesIds = _.union(PiroBackground.storiesIds, _.pluck(stories, 'id'))
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
    PiroBackground.db.getStories
      success: (stories) =>
        PiroBackground.db.deleteStoryById(story.id) for story in stories when _.indexOf(PiroBackground.storiesIds, story.id) is -1 and !PiroBackground._recentlyCreatedStory(story)
        PiroBackground.storiesIds = []
        PiroBackground.updateFinished()
    PiroBackground.db.getAllProjects
      success: (projects) =>
        projectIds = _.pluck(projects, 'id')
        PiroBackground.db.getProjectIcons
          success: (icons) =>
            PiroBackground.db.deleteProjectIcon(icon.id) for icon in icons when _.indexOf(projectIds, icon.id) is -1
  updateFinished: ->
    PiroBackground.updateState = false
    PiroBackground.checkUpdateState()
    PiroBackground.setAlarm()
    PiroBackground.updatePopup()
    PiroBackground._storiesForOmnibox()
  updatePopup: ->
    if PiroBackground.popupEvents? and PiroBackground.popupEvents.trigger?
      PiroBackground.popupEvents.trigger "update:data:finished", null
    else
      chrome.extension.sendMessage {type: "update:data:finished"}, (response) ->
        PiroBackground.initPopupView(response.events) if response? && response.events?
  # Context Menu
  initContextMenu: ->
    chrome.contextMenus.create
      title: "Go to Project/Story"
      contexts: ["link"]
      targetUrlPatterns: ["*://*.pivotaltracker.com/projects/*", "*://*.pivotaltracker.com/story/show/*"]
      type: "normal"
      id: "showPivotalStoryContextMenu"
    chrome.contextMenus.create
      title: "Create Story with selected Title"
      contexts: ["selection", "editable"]
      type: "normal"
      id: "createPivotalStoryContextMenu"
  clickContextMenu: (info, tab) ->
    indexUrl = chrome.extension.getURL('index.html')
    switch info.menuItemId
      when "createPivotalStoryContextMenu"
        PiroBackground.db.setStoryTitleTmpLS(info.selectionText)
        PiroBackground.openPopupUrl("#{indexUrl}#story/new", true)
      when "showPivotalStoryContextMenu"
        linkProjectRegexp = new RegExp("(.*):\/\/(www\.)?pivotaltracker.com\/projects\/([0-9]+)(.*)?", "i")
        linkStoryRegexp = new RegExp("(.*):\/\/(www\.)?pivotaltracker.com\/story\/show\/([0-9]+)(.*)?", "i")
        if info.linkUrl.match(linkProjectRegexp)? && info.linkUrl.match(linkProjectRegexp)[3]?
          projectId = info.linkUrl.match(linkProjectRegexp)[3]
          PiroBackground.openPopupUrl("#{indexUrl}#project/#{projectId}", true)
        else if info.linkUrl.match(linkStoryRegexp)? && info.linkUrl.match(linkStoryRegexp)[3]?
          storyId = info.linkUrl.match(linkStoryRegexp)[3]
          PiroBackground.openPopupUrl("#{indexUrl}#story/#{storyId}", true)
  # OMNIBOX  
  initOmniboxListeners: ->
    chrome.omnibox.onInputCancelled.addListener(PiroBackground.defaultOmniboxSuggestion)
    chrome.omnibox.onInputStarted.addListener ->
      PiroBackground.setOmniboxSuggestion('')
    chrome.omnibox.onInputChanged.addListener(PiroBackground.searchWithSuggestion)
    chrome.omnibox.onInputEntered.addListener(PiroBackground.enterOmniboxData)
  # default omnibox text
  defaultOmniboxSuggestion: ->
    chrome.omnibox.setDefaultSuggestion
      description: '<url><match>piro:</match></url> Search Pivotaltracker stories'
  # default omnibox text
  searchWithSuggestion: (text, suggest) ->
    results = []
    PiroBackground.setOmniboxSuggestion(text)
    return suggest(results) if text.length < 2
    searchReg = new RegExp(text.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1"), "gi")
    resStories = _.filter PiroBackground.omniboxStories, (story) ->
      story.id.match(searchReg)? or story.name.match(searchReg)? or story.description.match(searchReg)?
    for story in resStories
      description = story.name.replace(/<(?:.|\n)*?>/gm, '')
      description = description.replace(/&/g, '&amp;')
      description = description.replace(/[\n\t]/g, ' ')
      description = description.replace(RegExp(" {2,}", "g"), " ")
      description = description.replace(/<\/?pre>/g, '')
      description = description.replace(searchReg, "<match>#{text}</match>")
      results.push({ content: story.id, description: description})
    suggest(results)
  setOmniboxSuggestion: (text) ->
    defDescr = "<match><url>piro</url></match> "
    defDescr += if text.length > 0 then "<match>#{text}</match>" else "pivotal story name"
    chrome.omnibox.setDefaultSuggestion
      description: defDescr
  enterOmniboxData: (text) ->
    indexUrl = chrome.extension.getURL('index.html')
    mainUrl = "#{indexUrl}#story/#{text}/omnibox"
    PiroBackground.openPopupUrl(mainUrl)
  openPopupUrl: (url, isNew = false) ->
    indexUrl = chrome.extension.getURL('index.html')
    chrome.tabs.query {}, (tabs) ->
      chrome.tabs.remove(tab.id) for tab in tabs when tab.url.substring(0, indexUrl.length) is indexUrl and tabs.length > 1 and tab.active is false
    if isNew is true
      chrome.tabs.create {url: url, active: true}, (tab) ->
        chrome.tabs.update tab.id, {active: true}
    else
      chrome.tabs.query {active: true}, (tabs) ->
        chrome.tabs.update tab.id, {url: url} for tab in tabs
  # create story
  createAndSyncStory: (account, projectId, data, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.createStory projectId,
      data: data
      beforeSend: callbackParams.beforeSend
      success: (story, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground.db.setStory story,
              success: (story) =>
                callbackParams.success.call(null, story) if callbackParams.success?
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  updateAndSyncStory: (account, story, attributes, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.updateStory story,
      data: attributes
      beforeSend: callbackParams.beforeSend
      success: (storyInfo) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground.db.setStory storyInfo,
              success: =>
                callbackParams.success.call(null, storyInfo) if callbackParams.success?
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  updateAndSyncStoryOld: (account, story, attributes, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.updateStoryOld story,
      data: attributes
      beforeSend: callbackParams.beforeSend
      success: =>
        pivotalApi.getStory story.id,
          success: (storyInfo) =>
            PiroBackground.db = new PiroStorage
              success: =>
                PiroBackground.db.setStory storyInfo,
                  success: =>
                    callbackParams.success.call(null, storyInfo) if callbackParams.success?
          error: =>
            callbackParams.error.call(null) if callbackParams.error?
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  deleteAndSyncStory: (account, story, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.deleteStory story,
      beforeSend: callbackParams.beforeSend
      success: =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground.db.deleteStoryById story.id,
              success: =>
                callbackParams.success.call(null) if callbackParams.success?
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  createTaskAndSyncStory: (account, story, data, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.createTask story,
      data: data
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground._syncStory(pivotalApi, story, callbackParams)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  changeTaskAndSyncStory: (account, story, taskId, data, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.changeTask story, taskId,
      data: data
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground._syncStory(pivotalApi, story, callbackParams)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  sortTasksAndSyncStory: (account, story, sortData, callbackParams = {}) =>
    PiroBackground.db = new PiroStorage
      success: =>
        pivotalApi = new PivotaltrackerApi(account)
        PiroBackground._sortOneTask(pivotalApi, story, sortData, 0)
  deleteTaskAndSyncStory: (account, story, taskId, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.deleteTask story, taskId,
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground._syncStory(pivotalApi, story, callbackParams)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  createCommentAndSyncStory: (account, story, data, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.createComment story,
      data: data
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground._syncStory(pivotalApi, story, callbackParams)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  deleteCommentAndSyncStory: (account, story, commentId, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.deleteComment story, commentId,
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground._syncStory(pivotalApi, story, callbackParams)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  uploadAttachmentAndSyncStory: (account, story, formdata, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.uploadAttachment story, formdata,
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        setTimeout(=>
          PiroBackground.db = new PiroStorage
            success: =>
              PiroBackground._syncStory(pivotalApi, story, callbackParams)
        , 4000)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  deleteAttachmentAndSyncStory: (account, story, attachmentId, callbackParams = {}) =>
    callbackParams.beforeSend ||= -> true    
    pivotalApi = new PivotaltrackerApi(account)
    pivotalApi.deleteAttachment story, attachmentId,
      beforeSend: callbackParams.beforeSend
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db = new PiroStorage
          success: =>
            PiroBackground._syncStory(pivotalApi, story, callbackParams)
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  # private
  _storiesForOmnibox: =>
    omniboxDb = new PiroStorage
      success: ->
        omniboxDb.getStories
          success: (stories) ->
            PiroBackground.omniboxStories = stories
            omniboxDb = null
  _sortOneTask: (pivotalApi, story, sortData, iterator = 0) =>
    if sortData[iterator]?
      pivotalApi.changeTask story, sortData[iterator],
        data: 
          task:
            position: (iterator + 1)
        complete: =>
          PiroBackground._sortOneTask(pivotalApi, story, sortData, (iterator + 1))
    else
      PiroBackground._syncStory(pivotalApi, story, {})
  _syncStory: (pivotalApi, story, callbackParams = {}) =>
    pivotalApi.getStory story.id,
      success: (story, textStatus, jqXHR) =>
        PiroBackground.db.setStory story,
          success: (story) =>
            callbackParams.success.call(null, story) if callbackParams.success?
          error: =>
            callbackParams.error.call(null) if callbackParams.error?
      error: =>
        callbackParams.error.call(null) if callbackParams.error?
  _recentlyCreatedStory: (story) =>
    recentNum = 5 # 5 min
    createdAt = story.created_at
    return false unless createdAt?
    storyCreatedTime = moment(createdAt, "YYYY/MM/DD HH:mm:ss ZZ")
    return false if isNaN(storyCreatedTime.toDate().getTime())
    moment().diff(storyCreatedTime, "minutes") - storyCreatedTime.zone() <= recentNum
# init
chrome.runtime.onInstalled.addListener ->
  PiroBackground.init()
PiroBackground.initListeners()