root = global ? window
# namespace for backbone
root.PiroPopup = 
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
# main options object
root.PiroOptions = 
  bgPage: null
  db: null
  pivotalAccounts: null
  currentMainView: null
  init: ->
    # bg page
    chrome.runtime.getBackgroundPage (bgPage) ->
      PiroOptions.bgPage = bgPage
    # backbone monkey patch
    PiroOptions.monkeyBackboneCleanup()
    # db
    PiroOptions.db = new PiroStorage
      success: ->
        PiroOptions.pivotalAccounts = new PiroPopup.Collections.Accounts
        PiroOptions.db.getAccounts
          success: (accounts) ->
            PiroOptions.initUI(accounts)
  initUI: (accounts) ->
    PiroOptions.pivotalAccounts.reset(accounts)
    # routes
    new PiroPopup.Routers.Options
    # init history
    Backbone.history.start
      pushState: false
  # ui
  mainContainer: ->
    $('#mainContainer')
  updateMainContainer: (view) ->
    PiroOptions.currentMainView.destroyView() if PiroOptions.currentMainView? && PiroOptions.currentMainView.destroyView?
    PiroOptions.currentMainView = view
    PiroOptions.mainContainer().empty().html(PiroOptions.currentMainView.render().el)
  # patch backbone cleanup
  monkeyBackboneCleanup: ->
    Backbone.View::destroyView = ->
      @remove()
      @unbind()
      @onDestroyView() if @onDestroyView
    # jquery events for html5 api
    jQuery.event.props.push("dataTransfer")
# init
$ ->
  PiroOptions.init()