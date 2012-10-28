class PiroPopup.Views.StoriesShow extends Backbone.View
  template: SHT['stories/show']
  events:
    "click .story_delete_link"                      : "deleteStoryClick"
    "click .cancel_delete_story_link"               : "cancelDeleteStory"
    "click .confirm_delete_story_link"              : "confirmDeleteStory"
    # comment events
    "click .comment_open_link"                      : "openCommentClick"
    "click .cancel_open_comment_link"               : "cancelOpenComment"
    "submit .add_comment_form"                      : "addComment"
    "click .comment_delete_link"                    : "deleteCommentClick"
    "click .cancel_delete_comment_link"             : "cancelDeleteComment"
    "click .confirm_delete_comment_link"            : "confirmDeleteComment"
    # attachment events
    "change #attachmentForm > .fileInput"           : "uploadAttachment"
    "click .attachment_delete_link"                 : "deleteAttachmentClick"
    "click .cancel_delete_attachment_link"          : "cancelDeleteAttachment"
    "click .confirm_delete_attachment_link"         : "confirmDeleteAttachment"
  
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

  openCommentClick: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.add_comment_box').addClass('adding')
  cancelOpenComment: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.add_comment_box').removeClass('adding')
  addComment: (e) =>
    e.preventDefault()
    return false unless @$('.add_comment_text').val().length > 0
    attributes = 
      comment:
        text: @$('.add_comment_text').val()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.createCommentAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        attributes,
        success: (story) =>
          @model.set(story)
      )

  deleteCommentClick: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.comment_box').addClass('deleting')
  cancelDeleteComment: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.comment_box').removeClass('deleting')
  confirmDeleteComment: (e) =>
    e.preventDefault()
    commentId = @$(e.currentTarget).data('id')
    return false unless commentId?
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.deleteCommentAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @model.toJSON(),
        commentId,
        success: (story) =>
          @$(".comment_box[data-id='#{commentId}']").remove()
        error: =>
          # error
      )

  uploadAttachment: (e) =>
    e.preventDefault()
    files = e.currentTarget.files
    file = files[0] if files? and files.length > 0
    return false unless file?
    formdata = new FormData()
    formdata.append("Filedata", file)
    @$('#attachmentForm').addClass('loading')
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.uploadAttachmentAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @model.toJSON(), 
        formdata, 
        success: (story) =>
          @$('#attachmentForm').removeClass('loading')
          @model.set(story)
        error: =>
          @$('#attachmentForm').removeClass('loading')
          # error
      )
  deleteAttachmentClick: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.attachment_box').addClass('deleting')
  cancelDeleteAttachment: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.attachment_box').removeClass('deleting')
  confirmDeleteAttachment: (e) =>
    e.preventDefault()
    attachmentId = @$(e.currentTarget).data('id')
    return false unless attachmentId?
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.deleteAttachmentAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @model.toJSON(), 
        attachmentId, 
        success: (story) =>
          @$(".attachment_box[data-id='#{attachmentId}']").remove()
        error: =>
          # error
      )
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
    PiroPopup.globalEvents.off "update:data:finished", @getStoryAndRender