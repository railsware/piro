class PiroPopup.Views.OptionsAccount extends Backbone.View
  tagName: "li"
  template: SHT['options/account']
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-account-id", @model.get('id'))
    this

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
