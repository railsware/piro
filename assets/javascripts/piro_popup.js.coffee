root = global ? window

root.PiroPopup = 
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  bgPage: null
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
    # check mode
    PiroPopup.checkMode()
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
    appTabs = []
    chrome.tabs.query {}, (tabs) ->
      for tab in tabs
        appTabs.push(tab) if tab.url.substring(0, indexUrl.length) is indexUrl
      if appTabs.length > 1
        appTabs.shift()
        chrome.tabs.remove(tab.id) for tab in appTabs
        window.close()
        return false
      return true
  initUI: (accounts) ->
    _.extend(PiroPopup.globalEvents, Backbone.Events)
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
    # routes
    new PiroPopup.Routers.Popup
    # init history
    Backbone.history.start
      pushState: false
    # init favicon loader
    Piecon.setOptions
      color: "#ff0084" # Pie chart color
      background: "#bbb" # Empty pie chart color
      shadow: "#fff" # Outer ring color
      fallback: 'force' # Toggles displaying percentage in the title bar (possible values - true, false, 'force')
    # init bg
    chrome.runtime.getBackgroundPage (bgPage) ->
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.initPopupView(PiroPopup.globalEvents)
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
  clearStoriesContainer: ->
    PiroPopup.currentStoriesView.destroyView() if PiroPopup.currentStoriesView? && PiroPopup.currentStoriesView.destroyView?
    PiroPopup.storiesContainer().empty()
  storyContainer: ->
    $('#storyBox')
  updateStoryContainer: (view) ->
    PiroPopup.currentStoryView.destroyView() if PiroPopup.currentStoryView? && PiroPopup.currentStoryView.destroyView?
    PiroPopup.currentStoryView = view
    PiroPopup.storyContainer().empty().html(PiroPopup.currentStoryView.render().el)
  clearStoryContainer: ->
    PiroPopup.currentStoryView.destroyView() if PiroPopup.currentStoryView? && PiroPopup.currentStoryView.destroyView?
    PiroPopup.storyContainer().empty()
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