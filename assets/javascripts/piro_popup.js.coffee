root = global ? window

root.PiroPopup = 
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  bgPage: chrome.extension.getBackgroundPage()
  currentView: null
  globalEvents: {}
  init: ->
    # global events
    _.extend(PiroPopup.globalEvents, Backbone.Events)
    # events
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
    PiroPopup.currentView.destroyView() if PiroPopup.currentView? && PiroPopup.currentView.destroyView?
    PiroPopup.currentView = view
    PiroPopup.mainContainer().empty().html(PiroPopup.currentView.render().el)
  # patch backbone cleanup
  monkeyBackboneCleanup: ->
    Backbone.View::destroyView = ->
      @remove()
      @unbind()
      @onDestroyView()  if @onDestroyView
# init
$ ->
  PiroPopup.init()