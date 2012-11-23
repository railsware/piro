class PiroPopup.Views.StoriesShow extends Backbone.View
  template: SHT['stories/show']
  events:
    "click .story_label"                            : "filterByLabel"
    # update story
    "keydown .story_name"                           : "updateStoryName"
    "dblclick .open_story_description"              : "openStoryDescription"
    "click .cancel_edit_story_description"          : "closeStoryDescription"
    "submit .edit_story_description_form"           : "updateStoryDescription"
    "webkitspeechchange .story_description_speech"  : "changeStoryDescription"
    # change project id
    "change .change_project_id_selector"            : "changeProjectId"
    "click .cancel_change_project_link"             : "cancelChangeProjectId"
    "click .confirm_change_project_link"            : "confirmChangeProjectId"
    # delete story
    "click .story_delete_link"                      : "deleteStoryClick"
    "click .cancel_delete_story_link"               : "cancelDeleteStory"
    "click .confirm_delete_story_link"              : "confirmDeleteStory"
    # task events
    "click .task_open_link"                         : "openTaskClick"
    "click .cancel_open_task_link"                  : "cancelOpenTask"
    "submit .add_task_form"                         : "addTask"
    "change .task_complete_input"                   : "changeCompleteOfTask"
    "click .open_edit_task"                         : "openEditTask"
    "submit .edit_task_form"                        : "editTask"
    "click .close_edit_task_link"                   : "closeEditTask"
    "click .delete_task_link"                       : "deleteTask"
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
    $(@el).html(@template.render(_.extend(@model.toJSON(),
      pivotalProjects: PiroPopup.pivotalProjects.toJSON()
    )))
    @initProjectSelector()
    @initStoryTypeSelector()
    @initSortingTasks()
    this
    
  initProjectSelector: =>
    @$('select.change_project_id_selector').val(@model.get('project_id'))
  initStoryTypeSelector: =>
    @$('select.story_type_selector').val(@model.get('story_type').toLowerCase())
  initSortingTasks: =>
    @$("ul.tasks_list_box").sortable
      handle: '.sort_task'
      axis: 'y'
      placeholder: 'ui-state-highlight'
      update: (event) =>
        objects = @$("ul.tasks_list_box").find("li.task_box")
        objectIds = ($(object).data('id') for object in objects)
        if objectIds.length > 0
          chrome.runtime.getBackgroundPage (bgPage) =>
            PiroPopup.bgPage = bgPage
            PiroPopup.bgPage.PiroBackground.sortTasksAndSyncStory(
              PiroPopup.pivotalCurrentAccount.toJSON(),
              @model.toJSON(),
              objectIds
            )
  
  getStoryAndRender: =>
    PiroPopup.db.getStoryById @model.get('id'),
      success: (storyInfo) =>
        @model.set(storyInfo)

  remove: =>
    $(@el).remove()

  openStoryDescription: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.story_description_box').addClass('editing')
    @$('textarea.story_description').focus()
  closeStoryDescription: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.story_description_box').removeClass('editing')
  updateStoryDescription: (e) =>
    e.preventDefault()
    attributes = 
      story:
        description: @$('textarea.story_description').val()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.updateAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        attributes,
        success: (story) =>
          @model.set(story)
      )
  changeStoryDescription: (e) =>
    @$('textarea.story_description').val "#{@$('textarea.story_description').val()} #{@$('.story_description_speech').val()}"
    @$('.story_description_speech').val('')

  updateStoryName: (e) =>
    return false unless e.keyCode?
    return false if $(e.currentTarget).val().length is 0
    switch parseInt(e.keyCode)
      when 13 # Enter
        e.preventDefault()
        attributes = 
          story:
            name: $(e.currentTarget).val()
        chrome.runtime.getBackgroundPage (bgPage) =>
          PiroPopup.bgPage = bgPage
          PiroPopup.bgPage.PiroBackground.updateAndSyncStory(
            PiroPopup.pivotalCurrentAccount.toJSON(),
            @model.toJSON(),
            attributes,
            success: (story) =>
              @model.set(story)
          )
      when 27 # esc
        e.preventDefault()
        $(e.currentTarget).val(@model.get('name'))
      else
       return true

  changeProjectId: (e) =>
    if parseInt($(e.currentTarget).val()) isnt parseInt(@model.get('project_id'))
      @$('.change_project_box').removeClass('hidden')
    else
      @$('.change_project_box').addClass('hidden') unless @$('.change_project_box').hasClass('hidden')
  cancelChangeProjectId: (e) =>
    e.preventDefault()
    @$('.change_project_id_selector').val(@model.get('project_id'))
    @$('.change_project_box').addClass('hidden') unless @$('.change_project_box').hasClass('hidden')
  confirmChangeProjectId: (e) =>
    e.preventDefault()
    attributes = 
      story:
        project_id: @$('.change_project_id_selector').val()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.updateAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        attributes,
        success: (story) =>
          @model.set(story)
      )

  filterByLabel: (e) =>
    e.preventDefault()
    PiroPopup.globalEvents.trigger "filter:stories", "##{$(e.currentTarget).text()}"
    
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

  openTaskClick: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.add_task_box').addClass('adding')
    @$('input.add_task_description').focus()
  cancelOpenTask: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.add_task_box').removeClass('adding')
  addTask: (e) =>
    e.preventDefault()
    return false unless @$('.add_task_description').val().length > 0
    attributes = 
      task:
        description: @$('.add_task_description').val()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.createTaskAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        attributes,
        success: (story) =>
          @model.set(story)
      )
  changeCompleteOfTask: (e) =>
    taskId = @$(e.currentTarget).data('id')
    return false unless taskId?
    attributes = 
      task:
        complete: @$(e.currentTarget).is(':checked')
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.changeTaskAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @model.toJSON(),
        taskId,
        attributes,
        success: (story) =>
          # success
        error: =>
          # error
      )
  openEditTask: (e) =>
    e.preventDefault()
    $(e.currentTarget).parents('.task_box').addClass('editing').find('input.task_description_input').focus()
  closeEditTask: (e) =>
    e.preventDefault()
    $(e.currentTarget).parents('.task_box').removeClass('editing')
  editTask: (e) =>
    e.preventDefault()
    taskId = @$(e.currentTarget).parents('.task_box').data('id')
    return false unless taskId?
    attributes = 
      task:
        description: @$(e.currentTarget).find('.task_description_input').val()
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.changeTaskAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @model.toJSON(),
        taskId,
        attributes,
        success: (story) =>
          @model.set(story)
        error: =>
          # error
      )
  deleteTask: (e) =>
    e.preventDefault()
    taskId = @$(e.currentTarget).data('id')
    return false unless taskId?
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.deleteTaskAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @model.toJSON(),
        taskId,
        success: (story) =>
          @$(".task_box[data-id='#{taskId}']").remove()
        error: =>
          # error
      )

  openCommentClick: (e) =>
    e.preventDefault()
    @$(e.currentTarget).parents('.add_comment_box').addClass('adding')
    @$('textarea.add_comment_text').focus()
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