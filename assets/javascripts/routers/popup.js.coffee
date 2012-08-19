class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "*a"                      : "index"
  
  initialize: (options) =>
    @accounts = new PiroPopup.Collections.Accounts
    @accounts.reset(PiroStorage.getAccounts())
    PiroPopup.globalEvents.on "updated:data", @updatedData
    @on 'all', @beforRouting

  beforRouting: (trigger, args) =>
    switch trigger
      when "route:index"
        # index
      else
        # else
  index: =>
    return Backbone.history.navigate("login", {trigger: true, replace: false}) if @accounts.length is 0
    view = new PiroPopup.Views.PopupIndex(collection: @accounts)
    PiroPopup.updateMainContainer(view)
    
  login: =>
    return Backbone.history.navigate("", {trigger: true, replace: false}) if @accounts.length isnt 0
    view = new PiroPopup.Views.LoginIndex(collection: @accounts)
    PiroPopup.updateMainContainer(view)
    
  updatedData: =>
    Backbone.history.navigate("", {trigger: true, replace: false})
      