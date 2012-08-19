class PiroPopup.Views.ProjectsElement extends Backbone.View
  tagName: "li"
  className: "project"
  template: SHT['projects/element']
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    @renderStories()
    this
    
  renderStories: =>
    @childView = new PiroPopup.Views.StoriesIndex(collection: @model.stories)
    @$('.stories_box').html(@childView.render().el)

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
    @childView.destroyView() if @childView?
