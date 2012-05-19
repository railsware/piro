root = global ? window

root.PivotalRocketBackground =
  account: null
  pivotal_api_lib: null
  # popup
  popup: null
  # notification
  is_loading: false
  # tmp variables
  tmp_counter: 0
  tmp_action_counter: 0
  # updater timer
  update_timer: null
  # pregenerated templates list
  templates: {}
  # selected story
  selected_story: null
  # tabs
  owner_tabs: null
  requester_tabs: null
  # init background page (chrome loaded)
  init: ->
    if PivotalRocketStorage.get_accounts().length > 0
      if !PivotalRocketBackground.account?
        PivotalRocketBackground.account = PivotalRocketStorage.get_accounts()[0]
      # autoupdate
      PivotalRocketBackground.init_autoupdate()
      PivotalRocketBackground.autoupdate()
      # register omnibox
      PivotalRocketBackground.init_omnibox()
  # init autoupdate
  init_autoupdate: ->
    fcallback = -> PivotalRocketBackground.autoupdate()
    PivotalRocketBackground.update_timer = setInterval fcallback, PivotalRocketStorage.get_update_interval() * 60000    
  # load popup view
  load_popup_view: ->
    chrome.extension.getViews({type:"popup"})[0]
  # chrome icon
  init_icon_status: ->
    if PivotalRocketBackground.is_loading
      chrome.browserAction.setBadgeText({'text': '...'})
    else
      chrome.browserAction.setBadgeText({'text': ''})
  # popup open
  init_popup: ->
    PivotalRocketBackground.popup = PivotalRocketBackground.load_popup_view() if !PivotalRocketBackground.popup?
    if PivotalRocketBackground.popup?
      PivotalRocketBackground.selected_story = null
      PivotalRocketBackground.init_templates()
      PivotalRocketBackground.init_spinner()
      PivotalRocketBackground.init_bindings()
      if PivotalRocketStorage.get_accounts().length > 0
        PivotalRocketBackground.init_list_stories()
        PivotalRocketBackground.popup.$('#loginPage, #storyInfo').hide()
        PivotalRocketBackground.popup.$('#mainPage').show()
      else
        PivotalRocketBackground.popup.$('#mainPage, #storyInfo').hide()
        PivotalRocketBackground.popup.$('#loginPage .error_msg').hide()
        PivotalRocketBackground.popup.$('#loginPage').show()
        PivotalRocketBackground.popup.$('#loginUsername').focus()
  # init templates
  init_templates: ->
    if PivotalRocketBackground.popup?
      PivotalRocketBackground.templates.spinner           = Hogan.compile(PivotalRocketBackground.popup.$('#spinner_template').html())
      PivotalRocketBackground.templates.project           = Hogan.compile(PivotalRocketBackground.popup.$('#project_cell_template').html())
      PivotalRocketBackground.templates.story             = Hogan.compile(PivotalRocketBackground.popup.$('#story_info_template').html())
      PivotalRocketBackground.templates.add_story         = Hogan.compile(PivotalRocketBackground.popup.$('#add_story_template').html())
      PivotalRocketBackground.templates.add_story_result  = Hogan.compile(PivotalRocketBackground.popup.$('#add_story_result_template').html())
  # init global hotkeys
  init_global_hotkeys: ->
    $(PivotalRocketBackground.popup).keydown (event) ->
      return true if !(event.target? && event.target.nodeName? && -1 == jQuery.inArray(event.target.nodeName.toLowerCase(), ["input", "textarea", "select"]))
      return true if !(event.keyCode? && event.shiftKey? && event.shiftKey is true)
      if PivotalRocketBackground.popup.$('#ownerStories').is(':visible') is true 
        tabs = PivotalRocketBackground.owner_tabs
      else
        tabs = PivotalRocketBackground.requester_tabs
      return true unless tabs?
      switch event.keyCode
        # click on tabs (sh + 1, sh + 2 and sh + 3)
        when 49, 50, 51
          event.preventDefault()
          tabs.tabs('select', parseInt(event.keyCode) - 49)
        # min or max all projects (sh + 4 or sh + 5)
        when 52, 53
          event.preventDefault()
          PivotalRocketStorage.update_view_options_all_in_projects PivotalRocketBackground.account, 
            hide_project_cell: (if 52 == event.keyCode then true else false)
          PivotalRocketBackground.init_list_stories()
        # search field focus (sh + S)
        when 83
          event.preventDefault()
          PivotalRocketBackground.popup.$('#searchStories').focus()
        # update (sh + U)
        when 85
          event.preventDefault()
          PivotalRocketBackground.autoupdate()
        # new story (sh + N)
        when 78
          event.preventDefault()
          PivotalRocketBackground.show_add_story_view()
  # init popup bindings
  init_bindings: ->
    # main view
    PivotalRocketBackground.binding_main_view()
    # login
    PivotalRocketBackground.binding_login_view()
    # bindings for story show
    PivotalRocketBackground.binding_show_story_view()
  # init bindings for main view
  binding_main_view: ->
    # tabs
    PivotalRocketBackground.owner_tabs = PivotalRocketBackground.popup.$('#ownerStories').tabs()
    PivotalRocketBackground.requester_tabs = PivotalRocketBackground.popup.$('#requesterStories').tabs()
    # global hotkeys
    PivotalRocketBackground.init_global_hotkeys()
    # fine add block
    PivotalRocketBackground.open_fine_edit_block = (object) ->
      box = object.parents('.action_block')
      box.removeClass('loading').addClass('adding')
      if box.hasClass('add_task_block')
        PivotalRocketStorage.set_opened_by_type('opened_task_box', true)
        box.find('input.add_task_text').focus()
      else if box.hasClass('add_comment_block')
        box.find('textarea.add_comment_text').focus()
        PivotalRocketStorage.set_opened_by_type('opened_comment_box', true)
      return false
    PivotalRocketBackground.close_fine_edit_block = (object) ->
      box = object.parents('.action_block')
      box.removeClass('adding')
      if box.hasClass('add_task_block')
        PivotalRocketStorage.set_opened_by_type('opened_task_box', false)
      else if box.hasClass('add_comment_block')
        PivotalRocketStorage.set_opened_by_type('opened_comment_box', false)
      return false
    PivotalRocketBackground.popup.$("#storyInfo").on "click", "a.open_add_block", (event) =>
      PivotalRocketBackground.open_fine_edit_block($(event.target))
    PivotalRocketBackground.popup.$("#storyInfo").on "click", "a.close_add_block", (event) =>
      PivotalRocketBackground.close_fine_edit_block($(event.target))
    # fine delete
    PivotalRocketBackground.popup.$("#storyInfo").on "click", "a.fine_delete_link", (event) =>
      $(event.target).parents('.fine_delete').addClass('delete_confirm')
      return false
    PivotalRocketBackground.popup.$("#storyInfo").on "click", "a.fine_delete_cancel", (event) =>
      $(event.target).parents('.fine_delete').removeClass('delete_confirm')
      return false
    # update link
    PivotalRocketBackground.popup.$('#mainPage').on "click", "a.update_stories", (event) =>
      PivotalRocketBackground.autoupdate()
    # change account
    PivotalRocketBackground.popup.$('#changeAccount').change (event) =>
      PivotalRocketBackground.change_account()
    # change type list
    PivotalRocketBackground.popup.$('a.selecter_stories_type').click (event) =>
      PivotalRocketStorage.set_role($(event.target).data('value'))
      PivotalRocketBackground.change_view_type()
      return false
    # settings link
    PivotalRocketBackground.popup.$('#settingsLink').click (event) ->
      options_url = chrome.extension.getURL('options.html')
      chrome.tabs.create
        url: options_url
        active: true
      return false
    # projects sorting
    PivotalRocketBackground.popup.$("ul.projects_stories_list").sortable
      handle: 'span.sort_project'
      axis: 'y'
      placeholder: 'ui-state-highlight'
      update: (event) ->
        objects = $(event.target).parents("ul.projects_stories_list").find("li.project_cell")
        object_ids = []
        objects.each (index) ->
          object_ids.push($(this).data('projectId'))
        if object_ids.length > 0
          PivotalRocketStorage.sort_projects(PivotalRocketBackground.account, object_ids)
    .disableSelection()
    # projects toggle
    PivotalRocketBackground.popup.$("ul.projects_stories_list").on "click", "span.toggle_project", (event) =>
      PivotalRocketBackground.toggle_project_cell($(event.target))
    PivotalRocketBackground.popup.$("ul.projects_stories_list").on "dblclick", "span.dbclick_toggle_project", (event) =>
      PivotalRocketBackground.toggle_project_cell($(event.target))
    # click on story  
    PivotalRocketBackground.popup.$("#storiesTabs").on "click", "li.story_info", (event) =>
      element_object = $(event.target)
      PivotalRocketBackground.bind_story_cell(element_object)
    # search stories
    PivotalRocketBackground.popup.$('#mainPage').on "keyup", "#searchStories", (event) =>
      PivotalRocketBackground.init_list_stories()
    PivotalRocketBackground.popup.$('#mainPage').on "search", "#searchStories", (event) =>
      PivotalRocketBackground.init_list_stories() if 0 == $(event.target).val().length
    # open screen for add story
    PivotalRocketBackground.popup.$('a.add_new_story_link').click (event) =>
      PivotalRocketBackground.show_add_story_view()
      return false
    PivotalRocketBackground.popup.$('#addStoryView').on "click", "a.add_more_stories", (event) =>
      PivotalRocketBackground.show_add_story_view()
      return false
    # add story save link
    PivotalRocketBackground.popup.$('#addStoryView').on "click", "input.add_story_button", (event) =>
      PivotalRocketBackground.save_new_story()
      return false
    PivotalRocketBackground.popup.$('#addStoryView').on "keydown", "input.add_story_name, textarea.add_story_description, input.add_story_labels", (event) =>
      if ((event.metaKey? && event.metaKey is true) || (event.ctrlKey? && event.ctrlKey is true)) && event.keyCode? && 83 == event.keyCode
        event.preventDefault()
        PivotalRocketBackground.save_new_story()
        return false
    # add story cancel link
    PivotalRocketBackground.popup.$('#addStoryView').on "click", "a.add_story_close", (event) =>
      PivotalRocketBackground.popup.$('#storyInfo, #addStoryView').hide()
      PivotalRocketBackground.popup.$('#infoPanel').show()
      return false
  # init bindings for login view
  binding_login_view: ->
    PivotalRocketBackground.popup.$('#pivotalTokenAuthLink').click (event) =>
      PivotalRocketBackground.popup.$('a.login_switcher_link').removeClass('active')
      $(event.target).addClass('active')
      PivotalRocketBackground.popup.$('#pivotalBaseAuth').hide()
      PivotalRocketBackground.popup.$('#pivotalTokenAuth').show()
      PivotalRocketBackground.popup.$('#loginToken').focus()
      return false
    PivotalRocketBackground.popup.$('#pivotalBaseAuthLink').click (event) =>
      PivotalRocketBackground.popup.$('a.login_switcher_link').removeClass('active')
      $(event.target).addClass('active')
      PivotalRocketBackground.popup.$('#pivotalTokenAuth').hide()
      PivotalRocketBackground.popup.$('#pivotalBaseAuth').show()
      PivotalRocketBackground.popup.$('#loginUsername').focus()
      return false
    PivotalRocketBackground.popup.$('#loginButton').click (event) =>
      PivotalRocketBackground.login_by_user()
      return false
    PivotalRocketBackground.popup.$('#loginUsername, #loginPassword, #loginToken, #loginCompanyName').keydown (event) =>
      PivotalRocketBackground.login_by_user() if 13 == event.keyCode
  # init bindings for story show view
  binding_show_story_view: ->
    # search by labels
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.story_label", (event) =>
      label = $(event.target).data('label')
      if label?
        PivotalRocketBackground.popup.$("#searchStories").val(label).focus().trigger('keyup')
      return false
    # change of status
    PivotalRocketBackground.popup.$('#storyInfo').on "change", "select.change_story_state", (event) =>
      PivotalRocketBackground.change_story_status($(event.target), 'state')
    # change estimate of story
    PivotalRocketBackground.popup.$('#storyInfo').on "change", "select.change_story_estimate", (event) =>
      PivotalRocketBackground.change_story_status($(event.target), 'estimate')
    # add task in story
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "input.add_task_button", (event) =>
      PivotalRocketBackground.add_task_to_story($(event.target))
    PivotalRocketBackground.popup.$('#storyInfo').on "keydown", "input.add_task_text", (event) =>
      if (((event.metaKey? && event.metaKey is true) || (event.ctrlKey? && event.ctrlKey is true)) && event.keyCode? && 83 == event.keyCode) || (13 == event.keyCode)
        event.preventDefault()
        PivotalRocketBackground.add_task_to_story($(event.target))
        return false
      else if 27 == event.keyCode
        event.preventDefault()
        close_links = $(event.target).parents('div.add_task_block').find("a.close_add_block")
        PivotalRocketBackground.close_fine_edit_block($(close_links[0])) if close_links.length > 0
        return false
    # edit task
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.edit_task_link", (event) =>
      $(event.target).parents('li.task_block').addClass('editing').find('input.edit_task_text').focus()
      return false
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.cancel_task_link", (event) =>
      $(event.target).parents('li.task_block').removeClass('editing')
      return false
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "input.edit_task_button", (event) =>
      PivotalRocketBackground.edit_task_in_story($(event.target))
    PivotalRocketBackground.popup.$('#storyInfo').on "keydown", "input.edit_task_text", (event) =>
      if (((event.metaKey? && event.metaKey is true) || (event.ctrlKey? && event.ctrlKey is true)) && event.keyCode? && 83 == event.keyCode) || (13 == event.keyCode)
        event.preventDefault()
        PivotalRocketBackground.edit_task_in_story($(event.target))
        return false
      else if 27 == event.keyCode
        event.preventDefault()
        close_links = $(event.target).parents('li.task_block').removeClass('editing')
        return false
    # delete task
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.delete_task_link", (event) =>
      PivotalRocketBackground.delete_task_in_story($(event.target))
      return false
    # change task in story (completed/uncompleted)
    PivotalRocketBackground.popup.$('#storyInfo').on "change", "input.task_checkbox", (event) =>
      PivotalRocketBackground.change_task_status($(event.target))
    # filter tasks in story
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.filter_all_tasks", (event) =>
      PivotalRocketBackground.filter_tasks_by_state($(event.target))
      return false
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.filter_completed_tasks", (event) =>
      PivotalRocketBackground.filter_tasks_by_state($(event.target), 'completed')
      return false
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.filter_uncompleted_tasks", (event) =>
      PivotalRocketBackground.filter_tasks_by_state($(event.target), 'uncompleted')
      return false
    # add comment to story
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "input.add_comment_button", (event) =>
      PivotalRocketBackground.add_comment_to_story($(event.target))
      return false
    PivotalRocketBackground.popup.$('#storyInfo').on "keydown", "textarea.add_comment_text", (event) =>
      if ((event.metaKey? && event.metaKey is true) || (event.ctrlKey? && event.ctrlKey is true)) && event.keyCode? && 83 == event.keyCode
        event.preventDefault()
        PivotalRocketBackground.add_comment_to_story($(event.target))
        return false
      else if 27 == event.keyCode
        event.preventDefault()
        close_links = $(event.target).parents('div.add_comment_block').find("a.close_add_block")
        PivotalRocketBackground.close_fine_edit_block($(close_links[0])) if close_links.length > 0
        return false
    # delete comment from story
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.delete_comment_link", (event) =>
      PivotalRocketBackground.delete_comment_from_story($(event.target))
      return false
    # click on links in story description
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.desc_link", (event) =>
      chrome.tabs.create
        url: $(event.target).attr('href')
        active: false
      return false
  # change account
  change_account: ->
    account_id = PivotalRocketBackground.popup.$('#changeAccount').val()
    for account in PivotalRocketStorage.get_accounts()
      if parseInt(account.id) == parseInt(account_id)
        PivotalRocketBackground.account = account
        PivotalRocketBackground.init_list_stories()
        return true
    return false  
  # change view type
  change_view_type: ->
    if PivotalRocketBackground.popup? && PivotalRocketBackground.account?
      selected_type = PivotalRocketStorage.get_role()
      PivotalRocketBackground.popup.$("a.selecter_stories_type").removeClass('active')
      PivotalRocketBackground.popup.$("a.selecter_stories_type[data-value=#{selected_type}]").addClass('active')
      PivotalRocketBackground.popup.$('#storiesTabs div.tabs_content_block').hide()
      selector = PivotalRocketBackground.popup.$("#storiesTabs ##{selected_type}Stories")
      selector.show()
  # binding on story cell
  bind_story_cell: (element_object) -> 
    story_id = element_object.data("storyId")
    if !story_id?
      element_object = element_object.parents('li.story_info')
      story_id = element_object.data("storyId")
    project_id = element_object.parent('ul.list').data("projectId")
    requester = element_object.parent('ul.list').data("requested")
    requester = if requester? then true else false
    story = PivotalRocketStorage.find_story(project_id, story_id, requester)
    if story? && PivotalRocketBackground.popup?
      PivotalRocketBackground.selected_story = story.id
      PivotalRocketBackground.popup.$('#storiesTabs').find('li.story_info').removeClass('active')
      element_object.addClass('active')
      PivotalRocketBackground.show_story_info(story)  
  # show story details
  show_story_info: (story) ->
    return false unless story?
    project = PivotalRocketStorage.find_project(PivotalRocketBackground.account, story.project_id)
    # set points
    if project? && project.point_scale?
      story.point_scale = []
      for point in project.point_scale.split(",")
        story.point_scale.push
          point: point
    # parse labels
    if story.labels?
      labels = story.labels.split(",")
      story.labels_html = {text: ""}
      if labels.length > 0
        labels_array = []
        labels_array.push("<a href='#' class='story_label' data-label='##{label}'>#{label}</a>") for label in labels
        story.labels_html.text = labels_array.join(", ")
    # field for story type
    if story.story_type
      switch story.story_type
        when "feature"
          story.need_estimate = true if story.current_state? && jQuery.inArray(story.current_state, ["unscheduled", "unstarted", "started"]) != -1
          story.unestimated_feature = true if story.not_estimated? && story.not_estimated is true
          story.story_type_can_started = true
          story.story_type_many_statuses = true
        when "bug"
          story.story_type_can_started = true
          story.story_type_many_statuses = true
        when "chore"
          story.story_type_can_started = true
    # attachments, tasks and comments bool
    story.has_attachments = true if story.attachments? && story.attachments.length > 0
    story.has_tasks = true if story.tasks? && story.tasks.length > 0
    if story.comments? && story.comments.length > 0
      story.has_comments = true
      story.comments = for comment in story.comments
        comment.is_owner = true if comment.author? && comment.author.person? && comment.author.person.id? && 
        parseInt(comment.author.person.id) == parseInt(PivotalRocketBackground.account.id)
        comment
    # story open or closed blocks
    user_options = PivotalRocketStorage.get_user_options()
    story.opened_task_box = true if user_options.opened_task_box? && user_options.opened_task_box is true
    story.opened_comment_box = true if user_options.opened_comment_box? && user_options.opened_comment_box is true
    # generate template
    block_element = PivotalRocketBackground.popup.$('#storyInfo')
    block_element.empty().html(PivotalRocketBackground.templates.story.render(story))
    PivotalRocketBackground.popup.$('#addStoryView, #infoPanel').hide()
    block_element.show()
    # select selector for story state
    PivotalRocketBackground.popup.$('#storyInfo').find('select.change_story_state').val(story.current_state)
    # select selector for story estimate
    PivotalRocketBackground.popup.$('#storyInfo').find('select.change_story_estimate').val(story.estimate)
    # story description and comments
    PivotalRocketBackground.set_description_links()
    PivotalRocketBackground.set_comments_and_tasks_links()
    # set tasks filter
    if user_options.tasks_filter?
      PivotalRocketBackground.popup.$('#storyInfo').find('a.filter_tasks').removeClass('active')
      PivotalRocketBackground.popup.$('#storyInfo').find("a.filter_#{user_options.tasks_filter}_tasks")
      .addClass('active').trigger('click')
    # init story bindings
    PivotalRocketBackground.bindings_story_info(story)
    # init clippy
    chrome.extension.sendRequest
      clippy_for_story:
        id: story.id
        url: story.url
  # set links in description
  set_description_links: ->
    return false unless PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description').length > 0
    exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
    descr_object = PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description')
    descr_object.html(descr_object.html().replace(exp,"<a class='desc_link' href='$1'>$1</a>"))
  # set links in comments
  set_comments_and_tasks_links: ->
    exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
    # comments
    if PivotalRocketBackground.popup.$('#storyInfo').find('div.comment_description').length > 0
      $.each PivotalRocketBackground.popup.$('#storyInfo').find('div.comment_description'), (key, object) ->
        object = $(object)
        object.html(object.html().replace(exp,"<a class='desc_link' href='$1'>$1</a>"))
    # tasks
    if PivotalRocketBackground.popup.$('#storyInfo').find('label.task_description').length > 0
      $.each PivotalRocketBackground.popup.$('#storyInfo').find('label.task_description'), (key, object) ->
        object = $(object)
        object.html(object.html().replace(exp,"<a class='desc_link' href='$1'>$1</a>"))
  # init show bindings for story
  bindings_story_info: (story) ->
    # story title
    PivotalRocketBackground.popup.$('#storyInfo').find('h1.story_title').editable (value, settings) ->
      selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.update_story
        project_id: story.project_id
        story_id: story.id
        data:
          story:
            name: value
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: story.project_id
            story_id: story.id
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
            error: (jqXHR, textStatus, errorThrown) ->
              PivotalRocketBackground.init_list_stories()
              PivotalRocketBackground.popup.$('#storyInfo').find('h1.story_title').text(value)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          PivotalRocketBackground.popup.$('#storyInfo').find('h1.story_title').text(value)
      return '<img src="images/spinner3.gif" alt="loading..." title="loading..." />'
    ,
      type    : 'text'
      tooltip : ''
      indicator : '<img src="images/spinner3.gif" alt="loading..." title="loading..." />'
      cssclass  : 'editable-input'
      event   : 'dblclick'
      width   : 'none'
      height  : 'none'
      onblur  : 'ignore'
      onsubmit: ->
        PivotalRocketBackground.popup.$('#storyInfo').find('a.edit_story_title').show()
      onreset : ->
        PivotalRocketBackground.popup.$('#storyInfo').find('a.edit_story_title').show()
    PivotalRocketBackground.popup.$('#storyInfo').find('a.edit_story_title').click (event) ->
      event.preventDefault()
      $(event.target).hide()
      PivotalRocketBackground.popup.$('#storyInfo').find('h1.story_title').trigger('dblclick')
      return false
    # story description
    PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description').editable (value, settings) ->
      selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.update_story
        project_id: story.project_id
        story_id: story.id
        data:
          story:
            description: value
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: story.project_id
            story_id: story.id
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description').text(value).data({description: value})
              PivotalRocketBackground.set_description_links()
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
            error: (jqXHR, textStatus, errorThrown) ->
              PivotalRocketBackground.init_list_stories()
              PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description').text(value).data({description: value})
              PivotalRocketBackground.set_description_links()
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description').text(value).data({description: value})
          PivotalRocketBackground.set_description_links()
      return '<img src="images/spinner3.gif" alt="loading..." title="loading..." />'
    ,
      type    : 'textarea'
      submit  : '<input class="button success tiny" type="submit" value="Save" />'
      cancel  : '<a class="h4" href="#">Cancel</a>'
      button_separator: '<span class="mhs h4">or</span>'
      tooltip : ''
      indicator : '<img src="images/spinner3.gif" alt="loading..." title="loading..." />'
      cssclass  : 'editable-textarea'
      event   : 'dblclick'
      onblur  : 'ignore'
      data    : (value, settings) ->
        return PivotalRocketBackground.popup.$('#storyInfo').find('div.story_description').data('description')
    # init tasks sorting
    PivotalRocketBackground.popup.$('#storyInfo').find("ul.tasks_list").sortable
      handle: 'span.sort_task'
      axis: 'y'
      placeholder: 'ui-tasks-highlight'
      update: (event) ->
        objects = $(event.target).parents("ul.tasks_list").find("input.task_checkbox")
        story_id = objects.data('storyId')
        project_id = objects.data('projectId')
        selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
        object_ids = []
        objects.each (index) ->
          object_ids.push($(this).data('taskId'))
        if object_ids.length > 0
          PivotalRocketBackground.tmp_action_counter = object_ids.length
          pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
          for task_id, key in object_ids
            pivotal_lib.update_task
              project_id: project_id
              story_id: story_id
              task_id: task_id
              data:
                task:
                  position: (parseInt(key) + 1)
              complete: (jqXHR, textStatus) ->
                PivotalRocketBackground.tmp_action_counter--
                if PivotalRocketBackground.tmp_action_counter <= 0
                  pivotal_lib.get_story
                    project_id: story.project_id
                    story_id: story.id
                    success: (data, textStatus, jqXHR) ->
                      PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
                    error: (jqXHR, textStatus, errorThrown) ->
                      PivotalRocketBackground.init_list_stories()
    .disableSelection()
  # spinner for update stories
  init_spinner: ->
    PivotalRocketBackground.init_icon_status()
    return false if !(PivotalRocketBackground.popup? && PivotalRocketBackground.account?)
    hash_data =
      update_msg: chrome.i18n.getMessage("update_stories_link")
    if PivotalRocketBackground.is_loading
      hash_data.is_loading =
        loading_msg: chrome.i18n.getMessage("loading_msg")
  
    PivotalRocketBackground.popup.$('#loaderSpinner').empty().html(PivotalRocketBackground.templates.spinner.render(hash_data))
    # init account switcher
    PivotalRocketBackground.init_account_swither()
    PivotalRocketBackground.change_view_type()
  # account switch between accounts
  init_account_swither: ->
    return false if !(PivotalRocketBackground.popup? && PivotalRocketBackground.account?)
    PivotalRocketBackground.popup.$('#changeAccount').prop('disabled', PivotalRocketBackground.is_loading).empty()
    for account in PivotalRocketStorage.get_accounts()
      account_title = if account.company_name then account.company_name else account.email
      PivotalRocketBackground.popup.$('#changeAccount').append("<option value='#{account.id}'>#{account_title}</option>")
    PivotalRocketBackground.popup.$('#changeAccount').val(PivotalRocketBackground.account.id)
  # show stories list
  init_list_stories: ->
    return false if !(PivotalRocketBackground.popup? && PivotalRocketBackground.account?)
    search_text = null
    search_text = PivotalRocketBackground.popup.$('#searchStories').val() if PivotalRocketBackground.popup.$('#searchStories').val().length > 2
    stories_list = {current: [], done: [], icebox: [], rcurrent: [], rdone: [], ricebox: []}
    stories_count = {current: 0, done: 0, icebox: 0, rcurrent: 0, rdone: 0, ricebox: 0}
    stored_projects = PivotalRocketStorage.get_projects(PivotalRocketBackground.account)
    if stored_projects?
      for project in stored_projects
        stored_stories = PivotalRocketStorage.get_status_stories(project, false, search_text)
        if stored_stories?
          if stored_stories.current? && stored_stories.current.length > 0
            project.stories = stored_stories.current
            project.count_of_stories = stored_stories.current.length
            stories_count.current += project.count_of_stories
            stories_list.current.push(PivotalRocketBackground.templates.project.render(project))
          if stored_stories.done? && stored_stories.done.length > 0
            project.stories = stored_stories.done
            project.count_of_stories = stored_stories.done.length
            stories_count.done += project.count_of_stories
            stories_list.done.push(PivotalRocketBackground.templates.project.render(project))
          if stored_stories.icebox? && stored_stories.icebox.length > 0
            project.stories = stored_stories.icebox
            project.count_of_stories = stored_stories.icebox.length
            stories_count.icebox += project.count_of_stories
            stories_list.icebox.push(PivotalRocketBackground.templates.project.render(project))

        rstored_stories = PivotalRocketStorage.get_status_stories(project, true, search_text)
        if rstored_stories?
          project.is_requested_by_me = true
          if rstored_stories.current? && rstored_stories.current.length > 0
            project.stories = rstored_stories.current
            project.count_of_stories = rstored_stories.current.length
            stories_count.rcurrent += project.count_of_stories
            stories_list.rcurrent.push(PivotalRocketBackground.templates.project.render(project))
          if rstored_stories.done? && rstored_stories.done.length > 0
            project.stories = rstored_stories.done
            project.count_of_stories = rstored_stories.done.length
            stories_count.rdone += project.count_of_stories
            stories_list.rdone.push(PivotalRocketBackground.templates.project.render(project))
          if rstored_stories.icebox? && rstored_stories.icebox.length > 0
            project.stories = rstored_stories.icebox
            project.count_of_stories = rstored_stories.icebox.length
            stories_count.ricebox += project.count_of_stories
            stories_list.ricebox.push(PivotalRocketBackground.templates.project.render(project))

    no_stories_msg = "<li class='txt-center pal'>#{chrome.i18n.getMessage("no_stories_msg")}</li>"
    # owner
    PivotalRocketBackground.popup.$('#currentTabLabel').empty().text("#{chrome.i18n.getMessage("current_stories_tab")} (#{stories_count.current.toString()})")
    if stories_count.current > 0
      PivotalRocketBackground.popup.$('#currentStoriesList').empty().html(stories_list.current.join(""))
    else
      PivotalRocketBackground.popup.$('#currentStoriesList').empty().html(no_stories_msg)
    PivotalRocketBackground.popup.$('#doneTabLabel').empty().text("#{chrome.i18n.getMessage("done_stories_tab")} (#{stories_count.done.toString()})")
    if stories_count.done > 0
      PivotalRocketBackground.popup.$('#doneStoriesList').empty().html(stories_list.done.join(""))
    else
      PivotalRocketBackground.popup.$('#doneStoriesList').empty().html(no_stories_msg)
    PivotalRocketBackground.popup.$('#iceboxTabLabel').empty().text("#{chrome.i18n.getMessage("icebox_stories_tab")} (#{stories_count.icebox.toString()})")
    if stories_count.icebox > 0
      PivotalRocketBackground.popup.$('#iceboxStoriesList').empty().html(stories_list.icebox.join(""))
    else
      PivotalRocketBackground.popup.$('#iceboxStoriesList').empty().html(no_stories_msg)

    # requester
    PivotalRocketBackground.popup.$('#currentRequesterTabLabel').empty().text("#{chrome.i18n.getMessage("current_stories_tab")} (#{stories_count.rcurrent.toString()})")
    if stories_count.rcurrent > 0
      PivotalRocketBackground.popup.$('#currentRequesterStoriesList').empty().html(stories_list.rcurrent.join(""))
    else
      PivotalRocketBackground.popup.$('#currentRequesterStoriesList').empty().html(no_stories_msg)
    PivotalRocketBackground.popup.$('#doneRequesterTabLabel').empty().text("#{chrome.i18n.getMessage("done_stories_tab")} (#{stories_count.rdone.toString()})")
    if stories_count.rdone > 0
      PivotalRocketBackground.popup.$('#doneRequesterStoriesList').empty().html(stories_list.rdone.join(""))
    else
      PivotalRocketBackground.popup.$('#doneRequesterStoriesList').empty().html(no_stories_msg)
    PivotalRocketBackground.popup.$('#iceboxRequesterTabLabel').empty().text("#{chrome.i18n.getMessage("icebox_stories_tab")} (#{stories_count.ricebox.toString()})")
    if stories_count.ricebox > 0
      PivotalRocketBackground.popup.$('#iceboxRequesterStoriesList').empty().html(stories_list.ricebox.join(""))
    else
      PivotalRocketBackground.popup.$('#iceboxRequesterStoriesList').empty().html(no_stories_msg)
      
    # selected story
    if PivotalRocketBackground.selected_story?
      PivotalRocketBackground.bind_story_cell(PivotalRocketBackground.popup.$('#storiesTabs').find("li.story_#{PivotalRocketBackground.selected_story}"))
  # sync all data by account    
  initial_sync: (pivotal_account, callback_function = null) ->
    PivotalRocketBackground.is_loading = true
    PivotalRocketBackground.init_spinner()
    
    PivotalRocketBackground.pivotal_api_lib = new PivotalApiLib(pivotal_account)
    PivotalRocketBackground.pivotal_api_lib.get_projects
      success: (data, textStatus, jqXHR) =>
        allprojects = XML2JSON.parse(data, true)
        if allprojects.projects?
          projects = []
          projects = allprojects.projects.project if allprojects.projects? && allprojects.projects.project?
          projects = [projects] if projects.constructor != Array
          PivotalRocketStorage.set_projects(pivotal_account, projects)
          # projects
          PivotalRocketBackground.tmp_counter = projects.length * 2
          fcallback_counter = -> 
            PivotalRocketBackground.tmp_counter--
            if PivotalRocketBackground.tmp_counter <= 0
              PivotalRocketBackground.is_loading = false
              try
                PivotalRocketBackground.init_spinner()
                PivotalRocketBackground.init_list_stories()
              catch error
                PivotalRocketBackground.popup = null
                console.debug "Error: #{error}"
              callback_function() if callback_function?
        
          for project in projects
            PivotalRocketBackground.pivotal_api_lib.get_stories_for_project
              project: project
              complete: (jqXHR, textStatus) ->
                fcallback_counter()
              success: (data, textStatus, jqXHR, project) ->
                PivotalRocketBackground.save_stories_data_by_project(project, data)
              
            PivotalRocketBackground.pivotal_api_lib.get_stories_for_project
              requester: true
              project: project
              complete: (jqXHR, textStatus) ->
                fcallback_counter()
              success: (data, textStatus, jqXHR, project) ->
                PivotalRocketBackground.save_stories_data_by_project(project, data, true)
        # no projects
        else
          PivotalRocketBackground.init_list_stories()
          PivotalRocketBackground.is_loading = false
          PivotalRocketBackground.init_spinner()
          callback_function() if callback_function?
      error: (jqXHR, textStatus, errorThrown) ->
        # error
        PivotalRocketBackground.is_loading = false
        PivotalRocketBackground.init_spinner()
  # change story data
  change_story_status: (object, type = 'state') ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    story_val = object.val()
    story_id = object.data('storyId')
    project_id = object.data('projectId')
    pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
    return false if !(story_val? && story_id? && project_id?)
    switch type
      when 'estimate'
        switcher = 'estimate'
        data = {estimate: story_val}
      else
        switcher = 'state'
        data = {current_state: story_val}
    pivotal_lib.update_story
      project_id: project_id
      story_id: story_id
      data:
        story: data
      beforeSend: (jqXHR, settings) ->
        PivotalRocketBackground.popup.$('#storyInfo')
        .find("select.change_story_#{switcher}[data-story-id=#{story_id}]")
        .parents('div.change_story_box').addClass('loading')
      success: (data, textStatus, jqXHR) ->
        PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
      error: (jqXHR, textStatus, errorThrown) ->
        story = PivotalRocketStorage.find_story(project_id, story_id, selected_type_bol)
        if story?
          PivotalRocketBackground.popup.$('#storyInfo')
          .find("select.change_story_#{switcher}[data-story-id=#{story_id}]")
          .val(story.current_state).parents('div.change_story_box').removeClass('loading')
        else
          PivotalRocketBackground.popup.$('#storyInfo').find('div.change_story_box').removeClass('loading')
  # add task to story
  add_task_to_story: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    object_parent = object.parents('div.add_task_block')
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    story_id = object_parent.data('storyId')
    project_id = object_parent.data('projectId')
    description = object.parents('div.add_task_block').find('input.add_task_text').val()
    if story_id? && project_id? && description? && description.length > 0
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.add_task
        project_id: project_id
        story_id: story_id
        data:
          task:
            description: description
            complete: false
        beforeSend: (jqXHR, settings) ->
          object_parent.removeClass('adding').addClass('loading')
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: project_id
            story_id: story_id
            error: (jqXHR, textStatus, errorThrown) ->
              object_parent.removeClass('loading')
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          object_parent.removeClass('loading')
  # edit task in story
  edit_task_in_story: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    object_parent = object.parents('li.task_block')
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    object_data = object_parent.find('input.task_checkbox')
    task_id = object_data.data('taskId')
    story_id = object_data.data('storyId')
    project_id = object_data.data('projectId')
    description = object_parent.find('input.edit_task_text').val()
    if task_id? && story_id? && project_id? && description? && description.length > 0
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.update_task
        project_id: project_id
        story_id: story_id
        task_id: task_id
        data:
          task:
            description: description
        beforeSend: (jqXHR, settings) ->
          object_parent.removeClass('editing').addClass('loading')
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: project_id
            story_id: story_id
            error: (jqXHR, textStatus, errorThrown) ->
              object_parent.removeClass('loading')
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          object_parent.removeClass('loading')
  # edit task in story
  delete_task_in_story: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    object_parent = object.parents('li.task_block')
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    object_data = object_parent.find('input.task_checkbox')
    task_id = object_data.data('taskId')
    story_id = object_data.data('storyId')
    project_id = object_data.data('projectId')
    if task_id? && story_id? && project_id?
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.delete_task
        project_id: project_id
        story_id: story_id
        task_id: task_id
        beforeSend: (jqXHR, settings) ->
          object_parent.removeClass('editing').addClass('loading')
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: project_id
            story_id: story_id
            error: (jqXHR, textStatus, errorThrown) ->
              object_parent.removeClass('loading')
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          object_parent.removeClass('loading')
  # filter tasks by state
  filter_tasks_by_state: (object, state = null) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    PivotalRocketBackground.popup.$('#storyInfo').find('a.filter_tasks').removeClass('active')
    object.addClass('active')
    tasks_list = PivotalRocketBackground.popup.$('#storyInfo').find('ul.tasks_list')
    tasks_list.removeClass('completed uncompleted')
    tasks_list.addClass(state) if state?
    PivotalRocketStorage.set_tasks_filter(state)
  # change task in story
  change_task_status: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    completed = if object.is(':checked') then true else false
    task_id = object.data('taskId')
    story_id = object.data('storyId')
    project_id = object.data('projectId')
    if task_id? && story_id? && project_id?
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.update_task
        project_id: project_id
        story_id: story_id
        task_id: task_id
        data:
          task:
            complete: completed
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: project_id
            story_id: story_id
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
  # add comment to story
  add_comment_to_story: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    object_parent = object.parents('div.add_comment_block')
    story_id = object_parent.data('storyId')
    project_id = object_parent.data('projectId')
    description = object_parent.find('textarea.add_comment_text').val()
    if story_id? && project_id? && description? && description.length > 0
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.add_comment
        project_id: project_id
        story_id: story_id
        data:
          comment:
            text: description
        beforeSend: (jqXHR, settings) ->
          object_parent.removeClass('adding').addClass('loading')
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: project_id
            story_id: story_id
            error: (jqXHR, textStatus, errorThrown) ->
              object_parent.removeClass('loading')
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          object_parent.removeClass('loading')
  # delete comment from story
  delete_comment_from_story: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    selected_type_bol = PivotalRocketBackground.get_requester_or_owner_status()
    comment_id = object.data('id')
    object_parent = object.parents('li.comment_block')
    object_data = object.parents('ul.comments_list')
    story_id = object_data.data('storyId')
    project_id = object_data.data('projectId')
    if comment_id? && story_id? && project_id?
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.delete_comment
        project_id: project_id
        story_id: story_id
        comment_id: comment_id
        beforeSend: (jqXHR, settings) ->
          object_parent.addClass('loading')
        success: (data, textStatus, jqXHR) ->
          pivotal_lib.get_story
            project_id: project_id
            story_id: story_id
            error: (jqXHR, textStatus, errorThrown) ->
              object_parent.removeClass('loading')
            success: (data, textStatus, jqXHR) ->
              PivotalRocketBackground.story_changed_with_data(data, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.init_list_stories()
          object_parent.removeClass('loading')
  # story success changed
  story_changed_with_data: (data, requester = false) ->
    story = XML2JSON.parse(data, true)
    story = story.story if story.story?
    normalized_story = PivotalRocketBackground.normalize_story_for_saving(story)
    stories = PivotalRocketStorage.get_stories({id: story.project_id}, requester)
    new_stories = []
    in_list = false
    for st in stories
      if parseInt(st.id) == parseInt(normalized_story.id)
        new_stories.push(normalized_story)
        in_list = true
      else
        new_stories.push(st)
    new_stories.push(normalized_story) if in_list is false
    if new_stories.length > 0
      PivotalRocketStorage.set_stories({id: story.project_id}, new_stories, requester)
    PivotalRocketBackground.init_list_stories()
  # normalize story (after converting from xml to json)
  normalize_story_for_saving: (story) ->
    # normalize comments
    if story.comments?
      if story.comments.comment?
        if story.comments.comment.constructor != Array
          story.comments = [story.comments.comment]
        else
          story.comments = story.comments.comment
      else
        story.comments = [story.comments] if story.comments.constructor != Array
      
      clean_comments = []
      for comment in story.comments
        if comment.text? && comment.text.constructor == String
          clean_comments.push(comment)
      story.comments = clean_comments
    # normalize attachments
    if story.attachments?
      if story.attachments.attachment?
        if story.attachments.attachment.constructor != Array
          story.attachments = [story.attachments.attachment]
        else
          story.attachments = story.attachments.attachment
      else
        story.attachments = [story.attachments] if story.attachments.constructor != Array && story.attachments.url?
    (delete story.attachments) if story.attachments? && story.attachments.type?
    # normalize tasks
    if story.tasks?
      if story.tasks.task?
        if story.tasks.task.constructor != Array
          story.tasks = [story.tasks.task]
        else
          story.tasks = story.tasks.task
      else
        story.tasks = [story.tasks] if story.tasks.constructor != Array
    if story.tasks? && story.tasks.length > 0
      story.tasks = for task in story.tasks
        task.complete = if task.complete? && "true" == task.complete then true else false
        task.project_id = story.project_id
        task.story_id = story.id
        task
        
    if !story.estimate? || (story.estimate? && -1 == parseInt(story.estimate))
      story.estimate_text = "Unestimated"
      story.not_estimated = true
    else
      story.estimate_text = "#{story.estimate} points"
      story.is_estimated = true
        
    # normalize description
    if story.description? && jQuery.isEmptyObject(story.description)
      story.description = ""
      
    return story
  # save account after login
  save_account: (account) ->
    if account.email?
      PivotalRocketStorage.save_account(account)
  # login
  login_by_user: ->
    return false unless PivotalRocketBackground.popup?
    params = 
      success: (data, textStatus, jqXHR) ->
        account = XML2JSON.parse(data, true)
        account = account.person if account.person?
        PivotalRocketBackground.account = PivotalRocketBackground.save_account(account)
        PivotalRocketBackground.initial_sync(PivotalRocketBackground.account)
        PivotalRocketBackground.init_popup()
      
      error: (jqXHR, textStatus, errorThrown) ->
        if PivotalRocketBackground.popup?
          PivotalRocketBackground.popup.$('#loginPage').removeClass('locading')
          PivotalRocketBackground.popup.$('#loginPage .error_msg').show().text(errorThrown)
      beforeSend: (jqXHR, settings) ->
        if PivotalRocketBackground.popup?
          PivotalRocketBackground.popup.$('#loginPage .error_msg').hide()
          PivotalRocketBackground.popup.$('#loginPage').addClass('locading')
        
    if PivotalRocketBackground.popup.$('#pivotalBaseAuth').is(':visible')
      params.username = PivotalRocketBackground.popup.$('#loginUsername').val()
      params.password = PivotalRocketBackground.popup.$('#loginPassword').val()
      if params.username.length > 0 && params.password.length > 0
        pivotal_auth_lib = new PivotalAuthLib params
    else
      params.token = PivotalRocketBackground.popup.$('#loginToken').val()
      if params.token.length > 0
        pivotal_auth_lib = new PivotalAuthLib params 
  # autoupdate for all data
  autoupdate: ->
    if !PivotalRocketBackground.is_loading && PivotalRocketStorage.get_accounts().length > 0
      PivotalRocketBackground.autoupdate_by_account(0)
  #update with callback
  autoupdate_by_account: (iterator) ->
    if PivotalRocketStorage.get_accounts().length > 0 && PivotalRocketStorage.get_accounts()[iterator]?
      account = PivotalRocketStorage.get_accounts()[iterator]
      fcallback = -> PivotalRocketBackground.autoupdate_by_account(iterator + 1)
      PivotalRocketBackground.initial_sync(account, fcallback)
  # account list updated in options
  updated_accounts: ->
    if 0 == PivotalRocketStorage.get_accounts().length
      PivotalRocketBackground.account = null
    else if !PivotalRocketBackground.account?
      PivotalRocketBackground.account = PivotalRocketStorage.get_accounts()[0]
  # updated options on option page
  updated_options: ->
    # restart autoupdate
    clearInterval(PivotalRocketBackground.update_timer)
    PivotalRocketBackground.init_autoupdate()
  # save stories by project
  save_stories_data_by_project: (project, data, requester = false) ->
    stories = []
    allstories = XML2JSON.parse(data, true)
    stories = allstories.stories.story if allstories.stories? && allstories.stories.story?
    stories = [stories] if stories.constructor != Array
    if stories? && stories.length > 0
      normalize_stories = (PivotalRocketBackground.normalize_story_for_saving(story) for story in stories)
      PivotalRocketStorage.set_stories(project, normalize_stories, requester)
    else
      PivotalRocketStorage.delete_stories(project, requester)
  # get requester or no status
  get_requester_or_owner_status: ->
    selected_type = PivotalRocketStorage.get_role()
    selected_type = PivotalRocketBackground.popup.$("a.selecter_stories_type.active").data('value') if !selected_type?
    selected_type_bol = if selected_type? && "requester" == selected_type then true else false
    return selected_type_bol
  # toggle project cell in list
  toggle_project_cell: (object) ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    project_cell = object.parents("li.project_cell")
    project_id = project_cell.data('projectId')
    if project_cell.hasClass('hide-project')
      PivotalRocketStorage.update_view_options_in_project(PivotalRocketBackground.account, project_id, {hide_project_cell: false})
      PivotalRocketBackground.popup.$("ul.projects_stories_list").find("li.project_#{project_id}").removeClass('hide-project')
    else
      PivotalRocketStorage.update_view_options_in_project(PivotalRocketBackground.account, project_id, {hide_project_cell: true})
      PivotalRocketBackground.popup.$("ul.projects_stories_list").find("li.project_#{project_id}").addClass('hide-project')
  # show add story view
  show_add_story_view: ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    add_story_object = 
      # get and sort projects
      projects: PivotalRocketStorage.get_projects(PivotalRocketBackground.account).sort (a, b) ->
        if a.name? && b.name?
          return -1 if (a.name < b.name)
          return 1 if (a.name > b.name)
        return 0
    PivotalRocketBackground.popup.$('#addStoryView').empty().html(PivotalRocketBackground.templates.add_story.render(add_story_object))
    PivotalRocketBackground.popup.$('#addStoryView .errors_box').hide()
    PivotalRocketBackground.selected_story = null
    PivotalRocketBackground.popup.$('#storiesTabs').find('li.story_info').removeClass('active')
    PivotalRocketBackground.popup.$('#storyInfo, #infoPanel').hide()
    PivotalRocketBackground.popup.$('#addStoryView').show()
    PivotalRocketBackground.binding_add_story_view()
  # binding add story view
  binding_add_story_view: ->
    # set latest selected project
    PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_project_id').val(PivotalRocketStorage.get_last_created_project_id())
    # chosen
    PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_owner_id').chosen
      allow_single_deselect: true
    PivotalRocketBackground.popup.$('#addStoryView').find('select.chosen_selector').chosen()
    PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_project_id').change (event) ->
      # save latest selected project
      PivotalRocketStorage.set_last_created_project_id(PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_project_id').val())
      PivotalRocketBackground.changed_project_in_add_story()
    PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_story_type').change (event) ->
      PivotalRocketBackground.changed_story_type_on_add_story()
    PivotalRocketBackground.popup.$('#addStoryView').find('input.add_story_release_date').datepicker
      changeMonth: true
      changeYear: true
      minDate: 1
      dateFormat: "mm/dd/yy"
      showOtherMonths: true
      selectOtherMonths: true
    # assign owner to me
    PivotalRocketBackground.popup.$('#addStoryView').find('a.add_story_set_owner_on_me').click (event) ->
      PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_owner_id').
      val(PivotalRocketBackground.account.id.toString()).trigger("liszt:updated")
      return false
    PivotalRocketBackground.changed_project_in_add_story()
    PivotalRocketBackground.changed_story_type_on_add_story()
    # focus
    PivotalRocketBackground.popup.$('#addStoryView').find('input.add_story_name').focus()
  # add story change type
  changed_story_type_on_add_story: ->
    story_type = PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_story_type').val().toLowerCase()
    PivotalRocketBackground.popup.$('#addStoryView').find('div.add_story_point_box, div.add_story_release_date_box').hide()
    switch story_type
      when 'feature'
        PivotalRocketBackground.popup.$('#addStoryView').find('div.add_story_point_box').show()
      when 'release'
        PivotalRocketBackground.popup.$('#addStoryView').find('div.add_story_release_date_box').show()
  # add story changed project
  changed_project_in_add_story: ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    project_id = PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_project_id').val()
    return false unless project_id?
    project = PivotalRocketStorage.find_project(PivotalRocketBackground.account, project_id)
    return false unless project?
    # members
    requester_option_list = []
    owner_option_list = []
    owner_option_list.push "<option></option>"
    # sort members
    project.memberships = project.memberships.sort (a, b) ->
      if a.member? && a.member.person? && a.member.person.name? &&
      b.member? && b.member.person? && b.member.person.name?
        return -1 if (a.member.person.name < b.member.person.name)
        return 1 if (a.member.person.name > b.member.person.name)
      return 0
    for member in project.memberships
      if member.member? && member.member.person? && member.member.person.name?
        person = member.member.person
        requester_option_list.push "<option value='#{person.id}' data-name='#{person.name}'>#{person.name} (#{person.initials})</option>"
        owner_option_list.push "<option value='#{person.id}' data-name='#{person.name}'>#{person.name} (#{person.initials})</option>"
    PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_requester_id, select.add_story_owner_id').empty()
    if requester_option_list.length > 0
      PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_requester_id').html(requester_option_list.join(""))
      PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_owner_id').html(owner_option_list.join(""))
      PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_requester_id').val(PivotalRocketBackground.account.id.toString())
      PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_requester_id, select.add_story_owner_id').trigger("liszt:updated")
    # points
    if project.point_scale?
      point_scale = []
      point_scale.push "<option value='-1'>Unestimated</option>"
      for point in project.point_scale.split(",")
        point_scale.push "<option value='#{point}'>#{point} points</option>"
      if point_scale.length > 0
        PivotalRocketBackground.popup.$('#addStoryView').find('select.add_story_point')
        .html(point_scale.join("")).trigger("liszt:updated")
    if project.labels? && project.labels.length > 0
      project_labels = []
      for label in project.labels.split(",")
        project_labels.push label
      if project_labels.length > 0
        PivotalRocketBackground.popup.$('#addStoryView').find('input.add_story_labels')
        .bind "keydown", (event) ->
          return true unless PivotalRocketBackground.popup?
          if PivotalRocketBackground.popup.$('#addStoryView').find('input.add_story_labels').data("autocomplete")
            event.preventDefault() if event.keyCode is $.ui.keyCode.TAB && PivotalRocketBackground.popup.$('#addStoryView').find('input.add_story_labels').data("autocomplete").menu.active
        .autocomplete
          minLength: 0
          source: (request, response) ->
            terms = request.term.split( /,\s*/ )
            term = terms.pop()
            filtered_labels = []
            for label in project_labels
              filtered_labels.push(label) if $.inArray(label, terms) is -1
            response($.ui.autocomplete.filter(filtered_labels, term))
          focus: ->
            false
          select: (event, ui) ->
            terms = this.value.split( /,\s*/ )
            terms.pop()
            terms.push(ui.item.value)
            terms.push("")
            this.value = terms.join(", ")
            false
    else
      PivotalRocketBackground.popup.$('#addStoryView').find('input.add_story_labels').autocomplete( "destroy" )
  # save new story
  save_new_story: ->
    return false if !(PivotalRocketBackground.account? && PivotalRocketBackground.popup?)
    box = PivotalRocketBackground.popup.$('#addStoryView')
    project_id = box.find('select.add_story_project_id').val()
    title = box.find('input.add_story_name').val()
    story_type = box.find('select.add_story_story_type').val()
    story_point = box.find('select.add_story_point').val() if story_type? && 'feature' == story_type.toLowerCase()
    story_deadline = box.find('input.add_story_release_date').val() if story_type? && 'release' == story_type.toLowerCase()
    requester = box.find('select.add_story_requester_id').find(":selected").data('name')
    owner = box.find('select.add_story_owner_id').find(":selected").data('name')
    description = box.find('textarea.add_story_description').val()
    labels = box.find('input.add_story_labels').val()
    labels = $.trim(labels).replace(/,$/i, "")
    
    if title? && title.length > 0 && story_type? && project_id?
      story_data = 
        name: title
        story_type: story_type
        requested_by: requester
        description: description
        labels: labels
      story_data.estimate = story_point if story_point? && story_point.length > 0
      story_data.owned_by = owner if owner? && owner.length > 0
      story_data.deadline = story_deadline if story_deadline? && story_deadline.length > 0
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.add_story
        project_id: project_id
        data:
          story: story_data
        beforeSend: (jqXHR, settings) ->
          PivotalRocketBackground.popup.$('#addStoryView').find('div.errors_box').empty()
          PivotalRocketBackground.popup.$('#addStoryView').find('div.add_story_box').addClass('loading')
        success: (data, textStatus, jqXHR) ->
          story_data = XML2JSON.parse(data, true)
          PivotalRocketBackground.popup.$('#addStoryView').find('div.add_story_result').empty().removeClass('loader')
          .html(PivotalRocketBackground.templates.add_story_result.render(story_data.story))
          # update stories
          fcallback_update = -> 
            project = 
              id: project_id
            pivotal_lib.get_stories_for_project
              project: project
              beforeSend: (jqXHR, settings) ->
                if PivotalRocketBackground.is_loading is false
                  PivotalRocketBackground.is_loading = true
                  PivotalRocketBackground.init_spinner()
              complete: (jqXHR, textStatus) ->
                pivotal_lib.get_stories_for_project
                  requester: true
                  project: project
                  complete: (jqXHR, textStatus) ->
                    PivotalRocketBackground.is_loading = false
                    PivotalRocketBackground.init_spinner()
                    PivotalRocketBackground.init_list_stories()
                  success: (data, textStatus, jqXHR, project) ->
                    PivotalRocketBackground.save_stories_data_by_project(project, data, true)
              success: (data, textStatus, jqXHR, project) ->
                PivotalRocketBackground.save_stories_data_by_project(project, data)
          # update after 10 sec
          root.setTimeout(fcallback_update, 10000)
        error: (jqXHR, textStatus, errorThrown) ->
          PivotalRocketBackground.popup.$('#addStoryView').find('div.add_story_box').removeClass('loading')
          PivotalRocketBackground.popup.$('#addStoryView').find('.errors_box').show().html(errorThrown)
  # register omnibox (for search)
  init_omnibox: ->
    chrome.omnibox.onInputCancelled.addListener ->
      PivotalRocketBackground.default_omnibox_suggestion()
    chrome.omnibox.onInputStarted.addListener ->
      PivotalRocketBackground.set_omnibox_suggestion('')
    chrome.omnibox.onInputChanged.addListener (text, suggest) ->
      PivotalRocketBackground.set_omnibox_suggestion(text)
    chrome.omnibox.onInputEntered.addListener (text) ->
      chrome.tabs.query {active: true}, (tabs) ->
        for tab in tabs
          chrome.tabs.update tab.id, 
            url: "http://www.pivotaltracker.com/story/show/#{text}"
  # default omnibox text
  default_omnibox_suggestion: ->
    chrome.omnibox.setDefaultSuggestion
      description: '<url><match>piro:</match></url> Go by PivotalTracker ID'
  # default omnibox text
  set_omnibox_suggestion: (text) ->
    def_descr = "<match><url>piro</url></match><dim> [</dim> "
    def_descr += if text.length > 0 then "<match>#{text}</match>" else "pivotal story id"
    def_descr += "<dim> ]</dim>"
    chrome.omnibox.setDefaultSuggestion
      description: def_descr
      
$ ->
  PivotalRocketBackground.init()