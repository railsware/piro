root = global ? window

root.PiroBackground = 
  pivotalApi: null
  popupEvents: null
  projectsData: null
  init: ->
    PiroBackground.initAutoupdate()
  initPopupView: (events) ->
    PiroBackground.popupEvents = events
    #PiroBackground.initAutoupdate()
  initAutoupdate: ->
    PiroBackground.updateDataForAccount(PiroStorage.getAccounts()[0])
    #PiroBackground.popupEvents.trigger "updated:data", {} if PiroBackground.popupEvents?
  updateDataForAccount: (account) ->
    PiroBackground.pivotalApi = new PivotaltrackerApi(account)
    PiroBackground.pivotalApi.getProjects
      success: (data, textStatus, jqXHR) =>
        PiroBackground.projectsData = data
        PiroBackground.aggregateAllStories(account)
  aggregateAllStories: (account) ->
    projectsCount = PiroBackground.projectsData.length
    for project in PiroBackground.projectsData
      PiroBackground.pivotalApi.getStories project, 
        complete: =>
          projectsCount--
          PiroBackground.saveAllData(account) if projectsCount <= 0
        success: (project, data, textStatus, jqXHR) =>
          _.extend(PiroBackground.projectsData[_.indexOf(PiroBackground.projectsData, project)], {stories: data})
  saveAllData: (account) ->
    console.log JSON.stringify(PiroBackground.projectsData).length
    PiroStorage.setProjects(account, PiroBackground.projectsData)
# init
$ ->
  PiroBackground.init()