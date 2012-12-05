class PiroPopup.Views.StoriesSmart extends Backbone.View
  
  template: SHT['stories/smart']
  events:
    "click .stories_tab_link"           : "clickStoryTab"
    "keyup .stories_filter_input"       : "renderWithFilter"
  
  initialize: (options) ->
    @_typeOfView = if options.isOwner? and options.isOwner is true then "owner" else "requester"
    @collection = new PiroPopup.Collections.Stories
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    PiroPopup.globalEvents.on "update:data:finished", @getStoriesAndRender
    PiroPopup.globalEvents.on "filter:stories", @eventFilterStories
    PiroPopup.globalEvents.on "story::change::attributes", @changeStoryTriggered
    @childViews = []
    @_fetchInitialData()
  
  render: =>
    $(@el).html(@template.render(PiroPopup.db.getAllOptionsLS()))
    @$('input.stories_filter_input').clearSearch
      callback: @renderWithFilter
    @renderAll()
    this

  getStoriesAndRender: =>
    @_fetchInitialData()
    @renderWithFilter()

  renderWithFilter: (e) =>
    @renderAll()
    @_highlightLinks()

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
      storiesUserView: @_typeOfView
      filterText: @$('input.stories_filter_input').val()
    @renderOne(story) for story in stories
  
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

  _fetchInitialData: =>
    # fetch data  
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