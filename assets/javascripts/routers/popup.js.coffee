class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "project/:id"             : "project"
    "story/:id"               : "story"
    "*a"                      : "index"
  
  initialize: (options) =>
    @storiesList = null
    @on 'all', @beforRouting
    @mainView = new PiroPopup.Views.PopupIndex(collection: PiroPopup.pivotalAccounts, projects: PiroPopup.pivotalProjects)
    PiroPopup.updateMainContainer(@mainView)

  beforRouting: (trigger, args) =>
    switch trigger
      when "route:login"
        return Backbone.history.navigate("", {trigger: true, replace: false}) if PiroPopup.pivotalAccounts.length isnt 0
      else
        return Backbone.history.navigate("login", {trigger: true, replace: false}) if PiroPopup.pivotalAccounts.length is 0
  index: =>
    PiroPopup.updateMainContainer(@mainView)
  project: (id) =>
    @renderProjectStories(id)
  story: (id) =>
    PiroPopup.db.getStoryById id, 
      success: (storyInfo) =>
        return Backbone.history.navigate("", {trigger: true, replace: false}) unless storyInfo?
        # project
        if @storiesList?
          @renderStory(storyInfo.id)
        else
          @renderProjectStories storyInfo.project_id, 
            success: =>
              @renderStory(storyInfo.id)
  renderProjectStories: (projectId, params = {}) =>
    project = PiroPopup.pivotalProjects.get(projectId)
    return Backbone.history.navigate("", {trigger: true, replace: false}) unless project?
    PiroPopup.db.getStoriesByProject project.toJSON(), 
      success: (project, data) =>
        @storiesList = new PiroPopup.Collections.Stories
        @storiesList.reset(data)
        projectView = new PiroPopup.Views.StoriesIndex(collection: @storiesList)
        PiroPopup.updateStoriesContainer(projectView)
        params.success.call(null) if params.success?
  renderStory: (storyId) =>
    story = @storiesList.get(storyId)
    view = new PiroPopup.Views.StoriesShow(model: story)
    PiroPopup.updateStoryContainer(view)
  login: =>
    view = new PiroPopup.Views.LoginIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
      