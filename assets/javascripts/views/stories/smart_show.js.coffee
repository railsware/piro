class PiroPopup.Views.StoriesSmartShow extends PiroPopup.Views.StoriesShow
  confirmDeleteStory: (e) =>
    e.preventDefault()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.deleteAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        beforeSend: =>
          @$('.story_delete_control_box').html(PiroPopup.ajaxLoader)
        success: (story) =>
          projectId = @model.get('project_id')
          @model.trigger('destroy', @model, @model.collection, {})
          Backbone.history.navigate("smart_view", {trigger: true, replace: true})
      )