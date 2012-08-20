class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "project/:id"             : "project"
    "*a"                      : "index"
  
  initialize: (options) =>
    PiroPopup.globalEvents.on "updated:data", @updatedData
    @on 'all', @beforRouting
    #views
    @projectView = null

  beforRouting: (trigger, args) =>
    switch trigger
      when "route:index"
        # index
      else
        # else
  index: =>
    return Backbone.history.loadUrl("login") if PiroPopup.pivotalAccounts.length is 0
    view = new PiroPopup.Views.PopupIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
  login: =>
    return Backbone.history.loadUrl("") if PiroPopup.pivotalAccounts.length isnt 0
    view = new PiroPopup.Views.LoginIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
  project: (id) =>
    PiroPopup.db.getStoriesByProject {id: id}, 
      success: (project, data) =>
        stories = new PiroPopup.Collections.Stories
        stories.reset(data)
        projectView = new PiroPopup.Views.StoriesIndex(collection: stories)
        PiroPopup.updateStoriesContainer(projectView)
    
  updatedData: =>
    Backbone.history.navigate("", {trigger: true, replace: false})
      