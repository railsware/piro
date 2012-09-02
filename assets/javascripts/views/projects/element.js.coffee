class PiroPopup.Views.ProjectsElement extends Backbone.View
  tagName: "li"
  className: "project_element"
  template: SHT['projects/element']
  events:
    "click .project_link"           : "openStories"
    "click .project_settings"       : "openSettings"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-project-id", @model.get('id'))
    this

  remove: =>
    $(@el).remove()
    
  openStories: (e) =>
    e.preventDefault()
    Backbone.history.navigate("project/#{@model.get("id")}", {trigger: true, replace: false})
        
  openSettings: (e) =>
    e.preventDefault()
    @popupView = new PiroPopup.Views.ProjectsSettings(model: @model)
    PiroPopup.dialogContainer().empty().html(@popupView.render().el)
    PiroPopup.dialogContainer().dialog
      modal: true
      resizable: false
      draggable: false
      closeText: null
      dialogClass: "hide-title-bar"
      close: (event, ui) =>
        @popupView.destroyView() if @popupView? && @popupView.destroyView?
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
