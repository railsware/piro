class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  events:
    'change select.account_switcher'          : 'switchAccount'
    'click .update_data_for_accounts_link'    : 'updateDataTrigger'
    'click .add_story_link'                   : 'addStoryForm'
    'click .options_link'                     : 'openOptions'
  
  initialize: (options) ->
    @collection.on 'add', @render
    @collection.on 'reset', @render
    #projects 
    @projects = options.projects
    # global events
    PiroPopup.globalEvents.on "update:pivotal:data", @updatePivotalState
    PiroPopup.globalEvents.on "update:pivotal:progress", @updatePivotalUpdateProgress
    PiroPopup.globalEvents.on "update:data:finished", @_getAllStoriesForAccount
    PiroPopup.globalEvents.on "changed:story:fully", @_getAllStoriesForAccount
    PiroPopup.globalEvents.on "account:switched", @_getAllStoriesForAccount
    $(window).resize => @_recalculateHeight()
    @_allStoriesInProjects = 
      stories: []
      projects: []
  
  render: =>
    $(@el).html(@template.render(
      accounts: @collection.toJSON()
    ))
    @renderProjects()
    @_bindSearchStories()
    @_recalculateHeight()
    this

  renderProjects: =>
    @childView.destroyView() if @childView?
    @childView = new PiroPopup.Views.ProjectsIndex(collection: @projects)
    @$('#projectsBox').html(@childView.render().el)
  switchAccount: =>
    currentAccount = @collection.get(parseInt(@$('select.account_switcher').val()))
    return false unless currentAccount?
    PiroPopup.pivotalCurrentAccount = currentAccount
    PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(), 
      success: (projects) =>
        PiroPopup.pivotalProjects.reset(projects)
        PiroPopup.globalEvents.trigger "account:switched"
        Backbone.history.navigate("", {trigger: true, replace: true})

  updateDataTrigger: (e) =>
    e.preventDefault()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.startDataUpdate()
    
  addStoryForm: (e) =>
    e.preventDefault()
    Backbone.history.navigate("story/new", {trigger: true, replace: true})

  openOptions: (e) =>
    e.preventDefault()
    chrome.tabs.create
      url: chrome.extension.getURL('options.html')
      active: true

  updatePivotalState: (info) =>
    return false unless info?
    if info.updateState is true
      @$('#updateDataBox').addClass('loading')
      try
        Piecon.setProgress(0)
      catch e
        # no title
    else
      @$('#updateDataBox').removeClass('loading')
      try
        Piecon.reset()
      catch e
        # no title
  updatePivotalUpdateProgress: (info) =>
    return false unless info?
    @$('#updateDataBox').addClass('loading') unless @$('#updateDataBox').hasClass('loading')
    progress = parseInt(info.progress)
    try
      Piecon.setProgress(progress)
    catch e
      # no title

  _bindSearchStories: =>
    @_getAllStoriesForAccount()
    @$(".search_stories_input").autocomplete(
      minLength: 2
      appendTo: @$("#searchBlock")
      source: (request, response) =>
        response(@_getFilterSearchResultes(request.term))
      select: (event, ui) =>
        Backbone.history.navigate("story/#{ui.item.id}", {trigger: true, replace: true})
        @$(".search_stories_input").val('')
        false
    ).data("autocomplete")._renderItem = (ul, item) =>
      $("<li>").data("item.autocomplete", item).append("<a><img src='/public/images/story/#{item.story_type}.png' />#{item.label} <em class='muted'>(#{item.project.name})</em><br /></a>").appendTo(ul)

  _getAllStoriesForAccount: =>
    return false unless PiroPopup.pivotalCurrentAccount?
    PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(),
      success: (allProjects) =>
        @_allStoriesInProjects.projects = _.groupBy(allProjects, 'id')
        allProjectsIds = _.pluck(allProjects, 'id')
        PiroPopup.db.getStories
          success: (allStories) =>
            @_allStoriesInProjects.stories = _.filter allStories, (story) => _.indexOf(allProjectsIds, story.project_id) isnt -1

  _recalculateHeight: => @$(".container").height($("body").height() - 70)

  _getFilterSearchResultes: (term) =>
    data = []
    search = new RegExp($.ui.autocomplete.escapeRegex(term), "gi")
    for story in @_allStoriesInProjects.stories when @_allStoriesInProjects.stories.length
      if (story.name.match(search)? and story.name.match(search).length) or (story.description.match(search)? and story.description.match(search).length)
        project = {}
        project = @_allStoriesInProjects.projects[parseInt(story.project_id)][0] if @_allStoriesInProjects.projects[parseInt(story.project_id)]? and @_allStoriesInProjects.projects[parseInt(story.project_id)].length
        data.push
          id: story.id
          value: story.name
          label: story.name
          story_type: story.story_type
          project: project
        return data if data.length > 99
    return data

  onDestroyView: =>
    @collection.off 'add', @render
    @collection.off 'reset', @render
    PiroPopup.globalEvents.off "update:pivotal:data", @updatePivotalState
    PiroPopup.globalEvents.off "update:pivotal:progress", @updatePivotalUpdateProgress
    PiroPopup.globalEvents.off "update:data:finished", @_getAllStoriesForAccount
    PiroPopup.globalEvents.off "changed:story:fully", @_getAllStoriesForAccount
    PiroPopup.globalEvents.off "account:switched", @_getAllStoriesForAccount
    @childView.destroyView() if @childView?