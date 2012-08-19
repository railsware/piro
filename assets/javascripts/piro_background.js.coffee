root = global ? window

root.PiroBackground = 
  pivotalApi: null
  popupEvents: null
  init: ->
    PiroBackground.initAutoupdate()
  initPopupView: (events) ->
    PiroBackground.popupEvents = events
    PiroBackground.initAutoupdate()
  initAutoupdate: ->
    #PiroBackground.pivotalApi = new PivotaltrackerApi(PiroStorage.getAccounts()[0])
    #PiroBackground.pivotalApi.getProjects
    #  success: (data, textStatus, jqXHR) =>
    #    console.log data
    #PiroBackground.popupEvents.trigger "updated:data", {} if PiroBackground.popupEvents?
# init
$ ->
  PiroBackground.init()