class PiroPopup.Views.PopupIndex extends Backbone.View
  
  template: SHT['popup/index']
  
  initialize: ->
  
  render: =>
    $(@el).html(@template.render())
    this