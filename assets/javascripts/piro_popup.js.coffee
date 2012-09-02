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
  currentStoryView: null
  # data
  pivotalAccounts: null
  pivotalCurrentAccount: null
  pivotalProjects: null
  init: ->
    return unless PiroPopup.checkMode()
    # backbone monkey patch
    PiroPopup.monkeyBackboneCleanup()
    # db
    PiroPopup.db = new PiroStorage
      success: ->
        PiroPopup.pivotalAccounts = new PiroPopup.Collections.Accounts
        PiroPopup.pivotalProjects = new PiroPopup.Collections.Projects
        PiroPopup.db.getAccounts
          success: (accounts) ->
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
    # global events
    _.extend(PiroPopup.globalEvents, Backbone.Events)
    PiroPopup.bgPage.PiroBackground.initPopupView(PiroPopup.globalEvents)
    PiroPopup.pivotalAccounts.reset(accounts)
    if PiroPopup.pivotalAccounts.length > 0
      PiroPopup.pivotalCurrentAccount = PiroPopup.pivotalAccounts.first()
      # routing
      PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(), 
        success: (projects) =>
          PiroPopup.pivotalProjects.reset(projects)
          PiroPopup.initRouting()
    else
      PiroPopup.initRouting()
  initRouting: ->
    new PiroPopup.Routers.Popup
    # init history
    Backbone.history.start
      pushState: false
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
  storyContainer: ->
    $('#storyBox')
  updateStoryContainer: (view) ->
    PiroPopup.currentStoryView.destroyView() if PiroPopup.currentStoryView? && PiroPopup.currentStoryView.destroyView?
    PiroPopup.currentStoryView = view
    PiroPopup.storyContainer().empty().html(PiroPopup.currentStoryView.render().el)
  dialogContainer: ->
    $('#dialogContainer')
  # patch backbone cleanup
  monkeyBackboneCleanup: ->
    Backbone.View::destroyView = ->
      @remove()
      @unbind()
      @onDestroyView()  if @onDestroyView
    # jquery events for html5 api
    jQuery.event.props.push("dataTransfer")
# init
$ ->
  PiroPopup.init()