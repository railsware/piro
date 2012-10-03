class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "project/:id"             : "project"
    "story/new"               : "newStory"
    "story/:id"               : "showStory"
    "*a"                      : "index"
  
  initialize: (options) =>
    @storiesList = null
    @on 'all', @beforRouting
    @mainView = new PiroPopup.Views.PopupIndex(collection: PiroPopup.pivotalAccounts, projects: PiroPopup.pivotalProjects)
    PiroPopup.updateMainContainer(@mainView)

  beforRouting: (trigger, args) =>
    switch trigger
      when "route:login"
        return Backbone.history.navigate("", {trigger: true, replace: true}) if PiroPopup.pivotalAccounts.length isnt 0
      else
        return Backbone.history.navigate("login", {trigger: true, replace: true}) if PiroPopup.pivotalAccounts.length is 0
    # highlight links
    switch trigger
      when "route:project"
        @_highlightProject(args)
      when "route:showStory"
        PiroPopup.db.getStoryById args,
          success: (storyInfo) =>
            return false unless storyInfo?
            @_highlightProject(storyInfo.project_id)
            $('li.story_element').removeClass('active')
            $("li.story_element[data-story-id='#{storyInfo.id}']").addClass('active')
      when "route:newStory"
        $('li.story_element').removeClass('active')
      else
        $('li.story_element').removeClass('active')
        $('li.project_element').removeClass('active')
  index: =>
    PiroPopup.updateMainContainer(@mainView) unless PiroPopup.currentMainView is @mainView
    PiroPopup.clearStoriesContainer()
    PiroPopup.clearStoryContainer()
  newStory: =>
    view = new PiroPopup.Views.StoriesForm()
    PiroPopup.updateStoryContainer(view)
  project: (id) =>
    @renderProjectStories(id)
  showStory: (id) =>
    PiroPopup.db.getStoryById id, 
      success: (storyInfo) =>
        return Backbone.history.navigate("", {trigger: true, replace: true}) unless storyInfo?
        # project
        if @storiesList? && @storiesList.get(storyInfo.id)?
          @renderStory(storyInfo.id)
        else
          @renderProjectStories storyInfo.project_id, 
            success: =>
              @renderStory(storyInfo.id)
  renderProjectStories: (projectId, params = {}) =>
    project = PiroPopup.pivotalProjects.get(projectId)
    return Backbone.history.navigate("", {trigger: true, replace: true}) unless project?
    PiroPopup.db.getStoriesByProject project.toJSON(), 
      success: (project, data) =>
        @storiesList = new PiroPopup.Collections.Stories
        @storiesList.reset(data)
        projectView = new PiroPopup.Views.StoriesIndex(collection: @storiesList)
        PiroPopup.updateStoriesContainer(projectView)
        if params.success?
          params.success.call(null)
        else
          $('input.stories_filter_input').focus() if $('input.stories_filter_input').length
  renderStory: (storyId) =>
    story = @storiesList.get(storyId)
    view = new PiroPopup.Views.StoriesShow(model: story)
    PiroPopup.updateStoryContainer(view)
  login: =>
    view = new PiroPopup.Views.LoginIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
  # private
  _highlightProject: (projectId) =>
    $('li.project_element').removeClass('active')
    $("li.project_element[data-project-id='#{projectId}']").addClass('active')
      