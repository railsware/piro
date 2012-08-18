window.PiroPopup = 
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  currentView: null
  init: ->
    # backbone monkey patch
    PiroPopup.monkeyBackboneCleanup()
    # routing
    #new GPlusAxe.Routers.HangoutAxe
    # init history
    #Backbone.history.start
    #  pushState: true
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