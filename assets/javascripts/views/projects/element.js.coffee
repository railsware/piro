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
    PiroPopup.globalEvents.on "project:update:stories_counter:#{@model.get('id')}", @updateStoriesCounter

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-project-id", @model.get('id'))
    this
    
  updateStoriesCounter: (info) =>
    return null unless info? && info.storiesCount?
    @$('.stories_count').text(info.storiesCount)

  remove: =>
    $(@el).remove()
    
  openStories: (e) =>
    e.preventDefault()
    Backbone.history.navigate("project/#{@model.get("id")}", {trigger: true, replace: true})
        
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
      open: (event, ui) =>
        $('.ui-widget-overlay').on 'click', -> 
          PiroPopup.dialogContainer().dialog('close')
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
    PiroPopup.globalEvents.off "project:update:stories_counter:#{@model.get('id')}", @updateStoriesCounter
