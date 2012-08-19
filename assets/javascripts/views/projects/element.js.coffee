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
    view = new PiroPopup.Views.StoriesIndex(collection: @model.stories)
    @$('.stories_box').html(view.render().el)

  remove: =>
    $(@el).remove()
