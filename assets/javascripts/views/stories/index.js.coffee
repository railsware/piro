class PiroPopup.Views.StoriesIndex extends Backbone.View
  
  template: SHT['stories/index']
  events:
    "click .stories_tab_link"           : "clickStoryTab"
    "click .stories_user_link"          : "clickStoryUser"
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
    @childViews = []
  
  render: =>
    $(@el).html(@template.render(PiroPopup.db.getAllOptionsLS()))
    @renderAll()
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
    @renderOne(story) for story in stories

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