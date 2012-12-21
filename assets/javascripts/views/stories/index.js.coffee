class PiroPopup.Views.StoriesIndex extends Backbone.View
  template: SHT['stories/index']
  events:
    "click .stories_tab_link"           : "clickStoryTab"
    "click .stories_user_link"          : "clickStoryUser"
    "click .moscow_sort"                : "sortMoscowStories"
    "keyup .stories_filter_input"       : "renderWithFilter"
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    PiroPopup.globalEvents.on "update:data:finished", @getStoriesAndRender
    PiroPopup.globalEvents.on "filter:stories", @eventFilterStories
    PiroPopup.globalEvents.on "story::change::attributes", @changeStoryTriggered
    @childViews = []
  
  render: =>
    $(@el).html(@template.render(PiroPopup.db.getAllOptionsLS()))
    @$('input.stories_filter_input').clearSearch
      callback: @renderWithFilter
    @renderAll()
    this

  getStoriesAndRender: =>
    projectId = @collection.at(0).get("project_id") if @collection.length > 0
    return false unless projectId?
    PiroPopup.db.getStoriesByProject {id: projectId},
      success: (project, data) =>
        @collection.reset(data)

  renderOne: (story) =>
    view = new PiroPopup.Views.StoriesElement(model: story)
    @$('.stories_list').append(view.render().el)
    @childViews.push(view)

  renderAll: =>
    @$('.stories_list').empty()
    @cleanupChildViews()
    stories = @collection.getStoriesByFilters
      account: PiroPopup.pivotalCurrentAccount
      storiesTabView: PiroPopup.db.getStoriesTabViewLS()
      storiesUserView: PiroPopup.db.getStoriesUserViewLS()
      sortMoscow: PiroPopup.db.getMoscowSortLS()
      filterText: @$('input.stories_filter_input').val()
    if stories.length is 0
      @$(".empty-message").html("No results were filtered. Please try a different filter.") 
    else
      @$(".empty-message").html("")
    @renderOne(story) for story in stories
    PiroPopup.onHighlightLinks()
  
  eventFilterStories: (text) =>
    @$('input.stories_filter_input').val(text).trigger('change')
    @renderWithFilter()

  renderWithFilter: (e) =>
    @renderAll()

  changeStoryTriggered: (model) =>
    @renderWithFilter()

  clickStoryTab: (e) =>
    e.preventDefault()
    value = $(e.currentTarget).data('key')
    PiroPopup.db.setStoriesTabViewLS(value)
    @$('.stories_tabs li').removeClass('active')
    @$(".stories_tabs li.#{value}_stories_tab").addClass('active')
    @renderWithFilter()
    
  clickStoryUser: (e) =>
    e.preventDefault()
    value = $(e.currentTarget).data('key')
    PiroPopup.db.setStoriesUserViewLS(value)
    @$('.stories_user_tabs li').removeClass('active')
    @$(".stories_user_tabs li.#{value}_stories_user_tab").addClass('active')
    @renderWithFilter()
    
  sortMoscowStories: (e) =>
    e.preventDefault()
    state = !PiroPopup.db.getMoscowSortLS()
    PiroPopup.db.setMoscowSortLS(state)
    if state is true
      @$('.moscow_sort').addClass('on')
    else
      @$('.moscow_sort').removeClass('on')
    @renderWithFilter()

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