class PiroPopup.Views.StoriesIndex extends Backbone.View
  
  template: SHT['stories/index']
  events:
    "click .stories_tab_link"           : "clickStoryTab"
    "click .stories_user_link"          : "clickStoryUser"
    "keyup .stories_filter_input"       : "renderWithFilter"
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    @childViews = []
    @filterText = ""
  
  render: =>
    # filter text
    @filterText = @$('input.stories_filter_input').val()
    # render
    $(@el).html(@template.render(PiroPopup.db.getAllOptionsLS()))
    @renderAll()
    # set filter
    @$('input.stories_filter_input').val(@filterText)
    this

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
      filterText: @filterText
    @renderOne(story) for story in stories

  renderWithFilter: (e) =>
    @filterText = @$('input.stories_filter_input').val()
    @renderAll()

  clickStoryTab: (e) =>
    e.preventDefault()
    PiroPopup.db.setStoriesTabViewLS($(e.currentTarget).data('key'))
    @render()
    
  clickStoryUser: (e) =>
    e.preventDefault()
    PiroPopup.db.setStoriesUserViewLS($(e.currentTarget).data('key'))
    @render()

  onDestroyView: =>
    @collection.off 'add', @renderOne
    @collection.off 'reset', @renderAll
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []