class PiroPopup.Views.StoriesIndex extends Backbone.View
  
  template: SHT['stories/index']
  events:
    "click .stories_tab_link"           : "clickStoryTab"
    "click .stories_user_link"          : "clickStoryUser"
    "keyup .stories_filter_input"       : "renderWithFilter"
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    PiroPopup.globalEvents.on "update:data:finished", @getStoriesAndRender
    @childViews = []
  
  render: =>
    $(@el).html(@template.render(PiroPopup.db.getAllOptionsLS()))
    @renderAll()
    this

  getStoriesAndRender: =>
    projectId = @collection.at(0).get("project_id") if @collection.length > 0
    return false unless projectId?
    PiroPopup.db.getStoriesByProject {id: projectId},
      success: (project, data) =>
        @collection.reset(data)
        PiroPopup.globalEvents.trigger "route:highlight:links", null

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
      filterText: @$('input.stories_filter_input').val()
    @renderOne(story) for story in stories

  renderWithFilter: (e) =>
    @renderAll()
    @_highlightLinks()

  clickStoryTab: (e) =>
    e.preventDefault()
    value = $(e.currentTarget).data('key')
    PiroPopup.db.setStoriesTabViewLS(value)
    @$('.stories_tabs li').removeClass('active')
    @$(".stories_tabs li.#{value}_stories_tab").addClass('active')
    @renderAll()
    @_highlightLinks()
    
  clickStoryUser: (e) =>
    e.preventDefault()
    value = $(e.currentTarget).data('key')
    PiroPopup.db.setStoriesUserViewLS(value)
    @$('.stories_user_tabs li').removeClass('active')
    @$(".stories_user_tabs li.#{value}_stories_user_tab").addClass('active')
    @renderAll()
    @_highlightLinks()
    
  _highlightLinks: =>
    PiroPopup.globalEvents.trigger "route:highlight:links", null

  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    PiroPopup.globalEvents.off "update:data:finished", @getStoriesAndRender
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []