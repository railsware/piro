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
  initPopupView: (events) ->
    PiroBackground.popupEvents = events
    #PiroBackground.initAutoupdate()
  initAutoupdate: ->
    PiroBackground.db.getAccounts
      success: (accounts) =>
        PiroBackground.updateDataForAccount(accounts[0]) if accounts.length > 0
    #PiroBackground.popupEvents.trigger "updated:data", {} if PiroBackground.popupEvents?
  updateDataForAccount: (account) ->
    PiroBackground.pivotalApi = new PivotaltrackerApi(account)
    PiroBackground.pivotalApi.getProjects
      success: (data, textStatus, jqXHR) =>
        PiroBackground.db.setProjects account, data, 
          success: =>
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
        console.log "Done"
# init
$ ->
  PiroBackground.init()