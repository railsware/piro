class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "project/:id"             : "project"
    "story/new"               : "newStory"
    "story/:id"               : "showStory"
    "story/:id/omnibox"       : "showStory"
    "*a"                      : "index"
  
  initialize: (options) =>
    @storiesList = null
    @on 'all', @afterRouting
    PiroPopup.globalEvents.on "route:highlight:links", @_refreshLinks
    PiroPopup.globalEvents.on "update:data:finished", @_refreshView
    @mainView = new PiroPopup.Views.PopupIndex(collection: PiroPopup.pivotalAccounts, projects: PiroPopup.pivotalProjects)
    PiroPopup.updateMainContainer(@mainView)

  afterRouting: (trigger, args) =>
    switch trigger
      when "route:login"
        return Backbone.history.navigate("", {trigger: true, replace: true}) if PiroPopup.pivotalAccounts.length isnt 0
      else
        return Backbone.history.navigate("login", {trigger: true, replace: true}) if PiroPopup.pivotalAccounts.length is 0
    # highlight links
    @_hightlightLinks(trigger, args)

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
  _refreshView: =>
    Backbone.history.navigate("", {trigger: true, replace: true}) if $('#projectsBox').length is 0 || $('#projectsBox').children().length is 0
  _refreshLinks: =>
    return false if !Backbone.history? || !Backbone.history.fragment?
    for key, route of @routes
      regRoute = @_routeToRegExp(key)
      if Backbone.history.fragment.match(regRoute)?
        args = @_extractParameters(regRoute, Backbone.history.fragment)
        args = args[0] if args.length is 1
        return @_hightlightLinks("route:#{route}", args)
  _hightlightLinks: (trigger, args) =>
    switch trigger
      when "route:project"
        @_highlightProject(args)
      when "route:showStory"
        PiroPopup.db.getStoryById args,
          success: (storyInfo) =>
            return false unless storyInfo?
            @_highlightProject(storyInfo.project_id)
            return false if $("li.story_element[data-story-id='#{storyInfo.id}']").hasClass('active')
            $('li.story_element').removeClass('active')
            $("li.story_element[data-story-id='#{storyInfo.id}']").addClass('active')
      when "route:newStory"
        $('li.story_element').removeClass('active')
      else
        $('li.story_element').removeClass('active')
        $('li.project_element').removeClass('active')
  _highlightProject: (projectId) =>
    return false if $("li.project_element[data-project-id='#{projectId}']").hasClass('active')
    $('li.project_element').removeClass('active')
    $("li.project_element[data-project-id='#{projectId}']").addClass('active')
      