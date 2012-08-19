class PiroPopup.Views.StoriesIndex extends Backbone.View
  
  template: SHT['stories/index']
  
  initialize: ->
    @collection.on 'add', @renderOne
    @collection.on 'reset', @renderAll
  
  render: =>
    $(@el).html(@template.render())
    @renderAll()
    this

  renderOne: (story) =>
    view = new PiroPopup.Views.StoriesElement(model: story)
    @$('.stories_list').append(view.render().el)

  renderAll: =>
    @$('.stories_list').empty()
    @collection.each @renderOne