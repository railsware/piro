root = global ? window

root.PiroPopup = 
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  bgPage: chrome.extension.getBackgroundPage()
  db: null
  globalEvents: {}
  # views
  currentMainView: null
  currentStoriesView: null
  # data
  pivotalAccounts: null
  pivotalCurrentAccount: null
  init: ->
    return unless PiroPopup.checkMode()
    PiroPopup.db = new PiroStorage
      success: ->
        PiroPopup.pivotalAccounts = new PiroPopup.Collections.Accounts
        PiroPopup.db.getAccounts
          success: (accounts) =>
            PiroPopup.initUI(accounts)
  checkMode: ->
    indexUrl = chrome.extension.getURL('index.html')
    count = 0
    chrome.tabs.query {}, (tabs) ->
      for tab in tabs
        count++ if tab.url.substring(0, indexUrl.length) is indexUrl
        if count > 1
          window.close()
          return false
    return true
  initUI: (accounts) ->
    PiroPopup.pivotalAccounts.reset(accounts)
    PiroPopup.pivotalCurrentAccount = PiroPopup.pivotalAccounts.first() if PiroPopup.pivotalAccounts.length > 0
    # global events
    _.extend(PiroPopup.globalEvents, Backbone.Events)
    PiroPopup.bgPage.PiroBackground.initPopupView(PiroPopup.globalEvents)
    # backbone monkey patch
    PiroPopup.monkeyBackboneCleanup()
    # routing
    new PiroPopup.Routers.Popup
    # init history
    Backbone.history.start
      pushState: true
  # ui container
  mainContainer: ->
    $('#mainContainer')
  updateMainContainer: (view) ->
    PiroPopup.currentMainView.destroyView() if PiroPopup.currentMainView? && PiroPopup.currentMainView.destroyView?
    PiroPopup.currentMainView = view
    PiroPopup.mainContainer().empty().html(PiroPopup.currentMainView.render().el)
  storiesContainer: ->
    $('#storiesBox')
  updateStoriesContainer: (view) ->
    PiroPopup.currentStoriesView.destroyView() if PiroPopup.currentStoriesView? && PiroPopup.currentStoriesView.destroyView?
    PiroPopup.currentStoriesView = view
    PiroPopup.storiesContainer().empty().html(PiroPopup.currentStoriesView.render().el)
  # patch backbone cleanup
  monkeyBackboneCleanup: ->
    Backbone.View::destroyView = ->
      @remove()
      @unbind()
      @onDestroyView()  if @onDestroyView
# init
$ ->
  PiroPopup.init()