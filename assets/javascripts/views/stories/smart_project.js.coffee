class PiroPopup.Views.StoriesSmartProject extends Backbone.View
  tagName: "li"
  className: "grouped_story_element project-stories"
  template: SHT['stories/smart_element']
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove
    @childViews = []

  render: =>
    $(@el).html(@template.render(_.extend(@model.toJSON(), count: @model.stories.length)))
    $(@el).attr("data-project-id", @model.get('id'))
    @renderAll()
    this
    
  renderOne: (story) =>
    view = new PiroPopup.Views.StoriesSmartElement(model: story)
    @$('.stories_list').append(view.render().el)
    @childViews.push(view)

  renderAll: =>
    @$('.stories_list').empty()
    @cleanupChildViews()
    @model.stories.each @renderOne

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
    @cleanupChildViews()
  cleanupChildViews: =>
    view.destroyView() for view in @childViews
    @childViews = []