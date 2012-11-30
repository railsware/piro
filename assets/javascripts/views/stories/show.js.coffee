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
    # change story type
    "change .story_type_selector"                   : "changeStoryType"
    "click .clear_deadline_story_link"              : "clearStoryDeadline"
    # change story estimate
    "change .story_estimate_selector"               : "changeStoryEstimate"
    # change story state
    "change .story_state_selector"                  : "changeStoryState"
    # change requested by
    "change .story_requested_by"                    : "changeStoryRequestedBy"
    # change owned by
    "change .story_owned_by"                        : "changeStoryOwnedBy"
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
    $(@el).html(@template.render(_.extend(@model.toFullJSON(PiroPopup.pivotalCurrentAccount.toJSON()),
      pivotalProjects: PiroPopup.pivotalProjects.toJSON(),
      project:  PiroPopup.pivotalProjects.get(@model.get('project_id')).toJSON()
    )))
    @initStorySelectors()
    @initByStoryTypeView()
    @initSortingTasks()
    this
    
  initStorySelectors: =>
    chosenAttr = 
      container_class: "selector-chosen"
    @$('select.change_project_id_selector').val(@model.get('project_id')).chosen(chosenAttr)
    @$('select.story_estimate_selector').val(@model.get('estimate')).chosen(chosenAttr)
    @$('select.story_type_selector').val(@model.get('story_type').toLowerCase()).chosen(chosenAttr)
    @$('select.story_state_selector').val(@model.get('current_state').toLowerCase()).chosen(chosenAttr)
    @$('select.story_requested_by').val(@model.get('requested_by').id).chosen(chosenAttr) if @model.get('requested_by')?
    if @model.get('owned_by')? and @model.get('owned_by').id?
      @$('select.story_owned_by').val(@model.get('owned_by').id)
    else
      @$('select.story_owned_by').val("")
    @$('select.story_owned_by').chosen(chosenAttr)
  initByStoryTypeView: =>
    return false unless @$(".story_release_date").length
    @$(".story_release_date").datepicker
      showOn: "button"
      buttonImage: "public/images/calendar.gif"
      buttonImageOnly: true
      changeMonth: true
      changeYear: true
      minDate: 1
      dateFormat: "mm/dd/yy"
      showOtherMonths: true
      selectOtherMonths: true
      onSelect: (dateText, inst) =>
        attributes = 
          story:
            deadline: dateText
        @_changeStoryAttributes(attributes)
  clearStoryDeadline: (e) =>
    e.preventDefault()
    attributes = 
      story:
        deadline: ""
    @_changeStoryAttributes(attributes)
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
    return false if @$('textarea.story_description').val() is @model.get('description')
    attributes = 
      story:
        description: @$('textarea.story_description').val()
    @_changeStoryAttributes(attributes, (=> @$('.story_description_box').replaceWith(PiroPopup.ajaxLoader)))
  changeStoryDescription: (e) =>
    @$('textarea.story_description').val "#{@$('textarea.story_description').val()} #{@$('.story_description_speech').val()}"
    @$('.story_description_speech').val('')

  changeStoryType: (e) =>
    attributes = 
      story:
        story_type: @$('.story_type_selector').val()
    @_changeStoryAttributes(attributes, (=> @$('.story_type_selector_box').replaceWith(PiroPopup.ajaxLoader)))

  changeStoryEstimate: (e) =>
    attributes = 
      story:
        estimate: $(e.currentTarget).val()
    @_changeStoryAttributes(attributes, (=> @$('.story_estimate_selector_box').replaceWith(PiroPopup.ajaxLoader)))

  changeStoryState: (e) =>
    attributes = 
      story:
        current_state: $(e.currentTarget).val()
    @_changeStoryAttributes(attributes, (=> @$('.story_state_selector_box').replaceWith(PiroPopup.ajaxLoader)))

  changeStoryRequestedBy: (e) =>
    attributes = 
      story:
        requested_by: $(e.currentTarget).find(":selected").data("name")
    @_changeStoryAttributes(attributes, (=> @$('.story_requested_by_box').html(PiroPopup.ajaxLoader)))

  changeStoryOwnedBy: (e) =>
    attributes = 
      story:
        owned_by: $(e.currentTarget).find(":selected").data("name")
    @_changeStoryAttributes(attributes, (=> @$('.story_owned_by_box').html(PiroPopup.ajaxLoader)))

  updateStoryName: (e) =>
    return false unless e.keyCode?
    return false if $(e.currentTarget).val().length is 0
    switch parseInt(e.keyCode)
      when 13 # Enter
        e.preventDefault()
        return false if $(e.currentTarget).val() is @model.get('name')
        attributes = 
          story:
            name: $(e.currentTarget).val()
        @_changeStoryAttributes(attributes)
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
    @$('.change_project_id_selector').val(@model.get('project_id')).trigger("liszt:updated")
    @$('.change_project_box').addClass('hidden') unless @$('.change_project_box').hasClass('hidden')
  confirmChangeProjectId: (e) =>
    e.preventDefault()
    attributes = 
      story:
        project_id: @$('.change_project_id_selector').val()
    @_changeStoryAttributes(attributes, (=> @$('.story_project_id_box').replaceWith(PiroPopup.ajaxLoader)))

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
        beforeSend: =>
          @$('.story_delete_control_box').html(PiroPopup.ajaxLoader)
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
        beforeSend: =>
          @$('.add_task_box').replaceWith(PiroPopup.ajaxLoader)
        success: (story) =>
          @model.set(story)
        error: @render
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
        error: @render
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
        beforeSend: =>
          @$(e.currentTarget).parents('.task_box_div').replaceWith(PiroPopup.ajaxLoader)
        success: (story) =>
          @model.set(story)
        error: @render
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
        beforeSend: =>
          @$(e.currentTarget).parents('.task_control_box').replaceWith(PiroPopup.ajaxLoader)
        success: (story) =>
          @$(".task_box[data-id='#{taskId}']").remove()
        error: @render
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
        beforeSend: =>
          @$('.add_comment_box').replaceWith(PiroPopup.ajaxLoader)
        success: (story) =>
          @model.set(story)
        error: @render
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
        beforeSend: =>
          @$(e.currentTarget).parents('.delete_comment_control_box').html(PiroPopup.ajaxLoader)
        success: (story) =>
          @$(".comment_box[data-id='#{commentId}']").remove()
        error: @render
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
        beforeSend: =>
          @$('#attachmentForm').replaceWith(PiroPopup.ajaxLoader)
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
        error: @render
      )

  _changeStoryAttributes: (attributes, beforeSend = (-> true)) =>
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.updateAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        attributes,
        beforeSend: beforeSend
        success: (story) =>
          @model.set(story)
          PiroPopup.globalEvents.trigger "story::change::attributes", @model
        error: @render
      )
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
    PiroPopup.globalEvents.off "update:data:finished", @getStoryAndRender