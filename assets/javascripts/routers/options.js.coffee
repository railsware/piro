class PiroPopup.Routers.Options extends Backbone.Router
  routes:
    ""                        : "index"
    "*a"                      : "index"
  
  initialize: (options) =>
    @on 'all', @beforRouting
  beforRouting: (trigger, args) =>
    # trigger
  index: =>
    view = new PiroPopup.Views.OptionsIndex(collection: PiroOptions.pivotalAccounts)
    PiroOptions.updateMainContainer(view)
