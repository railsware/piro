class PiroPopup.Routers.Popup extends Backbone.Router
  routes:
    ""                        : "index"
    "login"                   : "login"
    "project/:id"             : "project"
    "story/new"               : "newStory"
    "story/:id"               : "showStory"
    "story/:id/omnibox"       : "showOmniboxStory"
    "smart_view"              : "smartIndexView"
    "smart_story/:id"         : "smartShowView"
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
    @_renderProjectStories(id)
  showStory: (id) =>
    PiroPopup.db.getStoryById id, 
      success: @_showStory
  showOmniboxStory: (id) =>
    PiroPopup.db.getStoryById id, 
      success: (storyInfo) =>
        return Backbone.history.navigate("", {trigger: true, replace: true}) unless storyInfo?
        PiroPopup.db.getAllRawProjects
          success: (accountProjects) =>
            for accountProject in accountProjects
              if _.indexOf(_.pluck(accountProject.projects, 'id'), storyInfo.project_id) isnt -1
                if parseInt(PiroPopup.pivotalCurrentAccount.get('id')) isnt parseInt(accountProject.account_id)
                  PiroPopup.pivotalCurrentAccount = PiroPopup.pivotalAccounts.get(accountProject.account_id)
                  $('select.account_switcher').val(accountProject.account_id)
                  return PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(), 
                    success: (projects) =>
                      PiroPopup.pivotalProjects.reset(projects)
                      PiroPopup.globalEvents.trigger "account:switched"
                      Backbone.history.navigate("story/#{id}", {trigger: true, replace: true})
                else
                  return Backbone.history.navigate("story/#{id}", {trigger: true, replace: true})
  login: =>
    view = new PiroPopup.Views.LoginIndex(collection: PiroPopup.pivotalAccounts)
    PiroPopup.updateMainContainer(view)
  smartIndexView: =>
    @_showSmartView(true)
  smartShowView: (id) =>
    @_showSmartView()
    PiroPopup.db.getStoryById id,
      success: @_showSmartStory
  # private
  _renderStory: (storyId) =>
    story = @storiesList.get(storyId)
    view = new PiroPopup.Views.StoriesShow(model: story)
    PiroPopup.updateStoryContainer(view)
  _renderProjectStories: (projectId, params = {}) =>
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
  _showStory: (story) =>
    return Backbone.history.navigate("", {trigger: true, replace: true}) unless story?
    # project
    if @storiesList? && @storiesList.get(story.id)?
      @_renderStory(story.id)
    else
      @_renderProjectStories story.project_id, 
        success: => @_renderStory(story.id)
  _showSmartView: (isForced = false) =>
    smartView = new PiroPopup.Views.StoriesSmart
    return false if PiroPopup.currentStoriesView? and PiroPopup.currentStoriesView instanceof PiroPopup.Views.StoriesSmart and isForced is false
    PiroPopup.updateStoriesContainer(smartView)
  _showSmartStory: (story) =>
    return Backbone.history.navigate("", {trigger: true, replace: true}) unless story?
    story = new PiroPopup.Models.Story(story)
    view = new PiroPopup.Views.StoriesSmartShow(model: story)
    PiroPopup.updateStoryContainer(view)
  _refreshView: =>
    Backbone.history.navigate("", {trigger: true, replace: true}) if $('#projectsBox').length is 0 || $('#projectsBox').children().length is 0
  # links
  _refreshLinks: =>
    return false if !Backbone.history? || !Backbone.history.fragment?
    for key, route of @routes
      regRoute = @_routeToRegExp(key)
      if Backbone.history.fragment.match(regRoute)?
        args = @_extractParameters(regRoute, Backbone.history.fragment)
        args = args[0] if args.length is 1
        return @_hightlightLinks("route:#{route}", args)
  _hightlightLinks: (trigger, args) =>
    @_resetHighlightLinks(trigger)
    switch trigger
      when "route:project"
        @_highlightProject(args)
      when "route:smartIndexView"
        @_highlightSmartProject()
      when "route:showStory"
        PiroPopup.db.getStoryById args,
          success: (storyInfo) =>
            return false unless storyInfo?
            @_highlightStory(storyInfo.id)
            @_highlightProject(storyInfo.project_id)
      when "route:smartShowView"
        PiroPopup.db.getStoryById args,
          success: (storyInfo) =>
            return false unless storyInfo?
            @_highlightStory(storyInfo.id)
            @_highlightSmartProject()
      else
        # nothing
  _resetHighlightLinks: (trigger) =>
    switch trigger
      when "route:showStory"
        $('.smart_view_box').removeClass('active') if $('.smart_view_link').hasClass('active')
      when "route:smartIndexView"
        $('li.story_element').removeClass('active')
        $('.project_link').removeClass('active')
      when "route:smartShowView"
        # 
      else
        $('.smart_view_link').removeClass('active')
        $('li.story_element').removeClass('active')
        $('.project_link').removeClass('active')
  _highlightProject: (projectId) =>
    return false if $(".project_element_uid_#{projectId}").hasClass('active')
    $('.project_link').removeClass('active')
    $(".project_element_uid_#{projectId}").addClass('active')
  _highlightStory: (storyId) =>
    return false if $("li.story_element_uid_#{storyId}").hasClass('active')
    $('li.story_element').removeClass('active')
    $("li.story_element_uid_#{storyId}").addClass('active')
  _highlightSmartProject: =>
    return false if $('.smart_view_link').hasClass('active')
    $('.smart_view_link').addClass('active')
      