class PiroPopup.Views.StoriesSmart extends Backbone.View
  
  template: SHT['stories/smart']
  events:
    "click .stories_tab_link"           : "clickStoryTab"
    "click .stories_smart_link"         : "clickStorySmart"
    "keyup .stories_filter_input"       : "renderWithFilter"
  
  initialize: (options) ->
    @collection = new PiroPopup.Collections.Projects
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    PiroPopup.globalEvents.on "update:data:finished", @renderWithFilter
    PiroPopup.globalEvents.on "filter:stories", @eventFilterStories
    PiroPopup.globalEvents.on "story::change::attributes", @changeStoryTriggered
    @childViews = []
  
  render: =>
    $(@el).html(@template.render(PiroPopup.db.getAllOptionsLS()))
    @$('input.stories_filter_input').clearSearch
      callback: @renderWithFilter
    @renderWithFilter()
    this

  renderWithFilter: (e) =>
    @_fetchInitialData()
    @_highlightLinks()

  renderOne: (project) =>
    view = new PiroPopup.Views.StoriesSmartElement(model: project)
    @$('.grouped_stories_list').append(view.render().el)
    @childViews.push(view)

  renderAll: =>
    @$('.grouped_stories_list').empty()
    @cleanupChildViews()
    @collection.each @renderOne
  
  eventFilterStories: (text) =>
    @$('input.stories_filter_input').val(text).trigger('change')
    @renderWithFilter()

  changeStoryTriggered: (model) =>
    @renderWithFilter()

  clickStoryTab: (e) =>
    e.preventDefault()
    value = $(e.currentTarget).data('key')
    PiroPopup.db.setStoriesTabViewLS(value)
    @$('.stories_tabs li').removeClass('active')
    @$(".stories_tabs li.#{value}_stories_tab").addClass('active')
    @renderWithFilter()

  clickStorySmart: (e) =>
    e.preventDefault()
    value = $(e.currentTarget).data('key')
    PiroPopup.db.setStoriesSmartViewLS(value)
    @$('.stories_user_tabs li').removeClass('active')
    @$(".stories_user_tabs li.#{value}_stories_user_tab").addClass('active')
    @renderWithFilter()

  _fetchInitialData: =>
    @$('.smart_loader').removeClass('hidden')
    PiroPopup.db.getProjects PiroPopup.pivotalCurrentAccount.toJSON(),
      success: (projects) =>
        PiroPopup.db.getStories
          success: (stories) =>
            projectIds = _.pluck(projects, 'id')
            stories = _.filter(stories, (story) =>
              storyModel = new PiroPopup.Models.Story(story)
              _.indexOf(projectIds, storyModel.get('project_id')) isnt -1 and
              storyModel.filterByState(PiroPopup.db.getStoriesTabViewLS()) and
              storyModel.filterByUser(PiroPopup.pivotalCurrentAccount, PiroPopup.db.getStoriesSmartViewLS()) and
              storyModel.filterByText(@$('input.stories_filter_input').val())
            )
            groupedStories = _.groupBy(stories, 'project_id')
            projectsData = []
            for project in projects when groupedStories[parseInt(project.id)]? and groupedStories[parseInt(project.id)].length > 0
              data = project
              data.stories = groupedStories[parseInt(project.id)]
              projectsData.push(data)
            @collection.reset(projectsData)
            @$('.smart_loader').addClass('hidden')
  _highlightLinks: =>
    PiroPopup.globalEvents.trigger "route:highlight:links", null

  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    PiroPopup.globalEvents.off "update:data:finished", @getStoriesAndRender
    PiroPopup.globalEvents.off "filter:stories", @eventFilterStories
    PiroPopup.globalEvents.off "story::change::attributes", @changeStoryTriggered
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []