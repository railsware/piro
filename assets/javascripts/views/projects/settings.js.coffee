class PiroPopup.Views.ProjectsSettings extends Backbone.View
  template: SHT['projects/settings']
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    this

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
