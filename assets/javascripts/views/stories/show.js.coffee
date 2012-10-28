class PiroPopup.Views.StoriesShow extends Backbone.View
  template: SHT['stories/show']
  events:
    "click .story_delete_link"          : "deleteStoryClick"
    "click .cancel_delete_story_link"   : "cancelDeleteStory"
    "click .confirm_delete_story_link"  : "confirmDeleteStory"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove
    PiroPopup.globalEvents.on "update:data:finished", @getStoryAndRender

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    this

  getStoryAndRender: =>
    PiroPopup.db.getStoryById @model.get('id'),
      success: (storyInfo) =>
        @model.set(storyInfo)

  remove: =>
    $(@el).remove()
    
  deleteStoryClick: (e) =>
    e.preventDefault()
    @$('.box_item').addClass('deleting')
  cancelDeleteStory: (e) =>
    e.preventDefault()
    @$('.box_item').removeClass('deleting')
  confirmDeleteStory: (e) =>
    e.preventDefault()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.deleteAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        success: (story) =>
          projectId = @model.get('project_id')
          @model.trigger('destroy', @model, @model.collection, {})
          Backbone.history.navigate("project/#{projectId}", {trigger: true, replace: true})
      )
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
    PiroPopup.globalEvents.off "update:data:finished", @getStoryAndRender