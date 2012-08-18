class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "*a"                      : "index"
  
  initialize: (options) =>
    @on 'all', @beforRouting

  beforRouting: (trigger, args) =>
    switch trigger
      when "route:index"
        # index
      else
        # else
        
  index: =>
    view = new PiroPopup.Views.PopupIndex()
    PiroPopup.updateMainContainer(view)