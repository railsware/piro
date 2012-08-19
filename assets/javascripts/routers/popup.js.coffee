class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "*a"                      : "index"
  
  initialize: (options) =>
    PiroPopup.globalEvents.on "updated:data", @updatedData
    @on 'all', @beforRouting

  beforRouting: (trigger, args) =>
    switch trigger
      when "route:index"
        # index
      else
        # else
  index: =>
    return Backbone.history.navigate("login", {trigger: true, replace: false}) if PiroPopup.pivotalAccounts.length is 0
    view = new PiroPopup.Views.PopupIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
  login: =>
    return Backbone.history.navigate("", {trigger: true, replace: false}) if PiroPopup.pivotalAccounts.length isnt 0
    view = new PiroPopup.Views.LoginIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
    
  updatedData: =>
    Backbone.history.navigate("", {trigger: true, replace: false})
      