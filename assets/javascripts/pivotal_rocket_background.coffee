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
  # updater timer
  update_timer: null
  # pregenerated templates list
  templates: {}
  # init background page (chrome loaded)
  init: ->
    if PivotalRocketStorage.get_accounts().length > 0
      if !PivotalRocketBackground.account?
        PivotalRocketBackground.account = PivotalRocketStorage.get_accounts()[0]
      # autoupdate
      PivotalRocketBackground.init_autoupdate()
      PivotalRocketBackground.autoupdate()
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
  # init templates
  init_templates: ->
    if PivotalRocketBackground.popup?
      PivotalRocketBackground.templates.spinner = Hogan.compile(PivotalRocketBackground.popup.$('#spinner_template').html())
      PivotalRocketBackground.templates.project = Hogan.compile(PivotalRocketBackground.popup.$('#project_cell_template').html())
      PivotalRocketBackground.templates.story = Hogan.compile(PivotalRocketBackground.popup.$('#story_info_template').html())
  # init popup bindings
  init_bindings: ->
    # tabs
    PivotalRocketBackground.popup.$('#ownerStories').tabs()
    PivotalRocketBackground.popup.$('#requesterStories').tabs()
    # login  
    PivotalRocketBackground.popup.$('#loginButton').click (event) =>
      PivotalRocketBackground.login_by_user()
    PivotalRocketBackground.popup.$('#loginUsername, #loginPassword, #loginCompanyName').keydown (event) =>
      PivotalRocketBackground.login_by_user() if 13 == event.keyCode
    # update link
    PivotalRocketBackground.popup.$('#mainPage').on "click", "a.update_stories", (event) =>
      PivotalRocketBackground.autoupdate()      
    # change type list
    PivotalRocketBackground.popup.$('#changeAccount').change (event) =>
      PivotalRocketBackground.change_account()
    # change type list
    PivotalRocketBackground.popup.$('#selecterStoriesType').change (event) =>
      PivotalRocketBackground.change_view_type()
    # click on story  
    PivotalRocketBackground.popup.$("#storiesTabs").on "click", "li.story_info", (event) =>
      element_object = $(event.target)
      PivotalRocketBackground.bind_story_cell(element_object)
    # search stories
    PivotalRocketBackground.popup.$('#mainPage').on "keyup", "#searchStories", (event) =>
      PivotalRocketBackground.init_list_stories()
    PivotalRocketBackground.popup.$('#mainPage').on "search", "#searchStories", (event) =>
      PivotalRocketBackground.init_list_stories() if 0 == $(event.target).val().length
    # bindings for story show
    # search by labels
    PivotalRocketBackground.popup.$('#storyInfo').on "click", "a.story_label", (event) =>
      label = $(event.target).data('label')
      if label?
        PivotalRocketBackground.popup.$("#searchStories").val(label).focus().trigger('keyup')
      return false
    # change of status
    PivotalRocketBackground.popup.$('#storyInfo').on "change", "select.change_story_state", (event) =>
      PivotalRocketBackground.change_story_state($(event.target))
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
      selected_type = PivotalRocketBackground.popup.$('#selecterStoriesType').val()
      PivotalRocketBackground.popup.$('#storiesTabs div.tabs_content_block').hide()
      selector = PivotalRocketBackground.popup.$("#storiesTabs ##{selected_type}Stories")
      selector.show()
  # binding on story cell
  bind_story_cell: (element_object) ->
    story_id = element_object.data("story-id")
    if !story_id
      element_object = element_object.parents('li.story_info')
      story_id = element_object.data("story-id")
    project_id = element_object.parent('ul').data("project-id")
    requester = element_object.parent('ul').data("requested")
    requester = if requester? then true else false
    story = PivotalRocketStorage.find_story(project_id, story_id, requester)
    if PivotalRocketBackground.popup?
      PivotalRocketBackground.popup.$('#storiesTabs').find('li.story_info').removeClass('active')
      element_object.addClass('active')
      PivotalRocketBackground.show_story_info(story)  
  # show story details
  show_story_info: (story) ->
    if story?
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
            story.story_type_can_started = true
            story.story_type_many_statuses = true
          when "bug"
            story.story_type_can_started = true
            story.story_type_many_statuses = true
          when "chore"
            story.story_type_can_started = true
      # generate template
      block_element = PivotalRocketBackground.popup.$('#storyInfo')
      block_element.empty().html(PivotalRocketBackground.templates.story.render(story))
      PivotalRocketBackground.popup.$('#infoPanel').hide()
      block_element.show()
      # select selector for story state
      PivotalRocketBackground.popup.$('#storyInfo').find('select.change_story_state').val(story.current_state)
      # init clippy
      chrome.extension.sendRequest
        clippy_for_story:
          id: story.id
          url: story.url
  # spinner for update stories
  init_spinner: ->
    PivotalRocketBackground.init_icon_status()
    if PivotalRocketBackground.popup? && PivotalRocketBackground.account?
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
    if PivotalRocketBackground.popup? && PivotalRocketBackground.account?
      PivotalRocketBackground.popup.$('#changeAccount').prop('disabled', PivotalRocketBackground.is_loading).empty()
      for account in PivotalRocketStorage.get_accounts()
        account_title = if account.company_name then account.company_name else account.email
        PivotalRocketBackground.popup.$('#changeAccount').append("<option value='#{account.id}'>#{account_title}</option>")
      PivotalRocketBackground.popup.$('#changeAccount').val(PivotalRocketBackground.account.id)
  # show stories list
  init_list_stories: ->
    if PivotalRocketBackground.popup? && PivotalRocketBackground.account?
      search_text = null
      if PivotalRocketBackground.popup.$('#searchStories').val().length > 2
        search_text = PivotalRocketBackground.popup.$('#searchStories').val()
      stories_list = {current: [], done: [], icebox: [], rcurrent: [], rdone: [], ricebox: []}
      stories_count = {current: 0, done: 0, icebox: 0, rcurrent: 0, rdone: 0, ricebox: 0}
      stored_projects = PivotalRocketStorage.get_projects(PivotalRocketBackground.account)
      if stored_projects?
        for project in stored_projects
          stored_stories = PivotalRocketStorage.get_status_stories(project, false, search_text)
          if stored_stories?
            if stored_stories.current? && stored_stories.current.length > 0
              project.stories = stored_stories.current
              stories_count.current += stored_stories.current.length
              stories_list.current.push(PivotalRocketBackground.templates.project.render(project))
            if stored_stories.done? && stored_stories.done.length > 0
              project.stories = stored_stories.done
              stories_count.done += stored_stories.done.length
              stories_list.done.push(PivotalRocketBackground.templates.project.render(project))
            if stored_stories.icebox? && stored_stories.icebox.length > 0
              project.stories = stored_stories.icebox
              stories_count.icebox += stored_stories.icebox.length
              stories_list.icebox.push(PivotalRocketBackground.templates.project.render(project))

          rstored_stories = PivotalRocketStorage.get_status_stories(project, true, search_text)
          if rstored_stories?
            project.is_requested_by_me = true
            if rstored_stories.current? && rstored_stories.current.length > 0
              project.stories = rstored_stories.current
              stories_count.rcurrent += rstored_stories.current.length
              stories_list.rcurrent.push(PivotalRocketBackground.templates.project.render(project))
            if rstored_stories.done? && rstored_stories.done.length > 0
              project.stories = rstored_stories.done
              stories_count.rdone += rstored_stories.done.length
              stories_list.rdone.push(PivotalRocketBackground.templates.project.render(project))
            if rstored_stories.icebox? && rstored_stories.icebox.length > 0
              project.stories = rstored_stories.icebox
              stories_count.ricebox += rstored_stories.icebox.length
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
  # sync all data by account    
  initial_sync: (pivotal_account, callback_function = null) ->
    PivotalRocketBackground.is_loading = true
    PivotalRocketBackground.init_spinner()
    
    PivotalRocketBackground.pivotal_api_lib = new PivotalApiLib(pivotal_account)
    PivotalRocketBackground.pivotal_api_lib.get_projects
      success: (data, textStatus, jqXHR) =>
        allprojects = XML2JSON.parse(data, true)
        projects = []
        projects = allprojects.projects.project if allprojects.projects? && allprojects.projects.project?
        projects = [projects] if projects.constructor != Array
        PivotalRocketStorage.set_projects(pivotal_account, projects)
        PivotalRocketBackground.tmp_counter = projects.length * 2
        for project in projects
          PivotalRocketBackground.pivotal_api_lib.get_stories_for_project
            project: project
            complete: (jqXHR, textStatus) ->
              PivotalRocketBackground.tmp_counter--
              if PivotalRocketBackground.tmp_counter <= 0
                PivotalRocketBackground.init_list_stories()
                PivotalRocketBackground.is_loading = false
                PivotalRocketBackground.init_spinner()
                if callback_function?
                  callback_function()
            success: (data, textStatus, jqXHR, project) ->
              stories = []
              allstories = XML2JSON.parse(data, true)
              stories = allstories.stories.story if allstories.stories? && allstories.stories.story?
              stories = [stories] if stories.constructor != Array
              if stories? && stories.length > 0
                normalize_stories = (PivotalRocketBackground.normalize_story_for_saving(story) for story in stories)
                PivotalRocketStorage.set_stories(project, normalize_stories)
              else
                PivotalRocketStorage.delete_stories(project)
            error: (jqXHR, textStatus, errorThrown) ->
              # error
              
          PivotalRocketBackground.pivotal_api_lib.get_stories_for_project_requester
            project: project
            complete: (jqXHR, textStatus) ->
              PivotalRocketBackground.tmp_counter--
              if PivotalRocketBackground.tmp_counter <= 0
                PivotalRocketBackground.init_list_stories()
                PivotalRocketBackground.is_loading = false
                PivotalRocketBackground.init_spinner()
                if callback_function?
                  callback_function()
            success: (data, textStatus, jqXHR, project) ->
              stories = []
              allstories = XML2JSON.parse(data, true)
              stories = allstories.stories.story if allstories.stories? && allstories.stories.story?
              stories = [stories] if stories.constructor != Array
              if stories? && stories.length > 0
                normalize_stories = (PivotalRocketBackground.normalize_story_for_saving(story) for story in stories)
                PivotalRocketStorage.set_stories(project, normalize_stories, true)
              else
                PivotalRocketStorage.delete_stories(project, true)
            error: (jqXHR, textStatus, errorThrown) ->
              # error
            
      error: (jqXHR, textStatus, errorThrown) ->
        # error
        PivotalRocketBackground.is_loading = false
        PivotalRocketBackground.init_spinner()
  # change story state
  change_story_state: (object) ->
    if PivotalRocketBackground.account? && PivotalRocketBackground.popup?
      selected_type = PivotalRocketBackground.popup.$('#selecterStoriesType').val()
      selected_type_bol = if selected_type && "requester" == selected_type then true else false
      story_state = object.val()
      story_id = object.data('storyId')
      project_id = object.data('projectId')
      pivotal_lib = new PivotalApiLib(PivotalRocketBackground.account)
      pivotal_lib.update_story
        project_id: project_id
        story_id: story_id
        data:
          story:
            current_state: story_state
        success: (data, textStatus, jqXHR) ->
          # TODO: need DRY this method (repeats)
          params = 
            project: 
              id: project_id
            success: (data, textStatus, jqXHR, project) ->
              stories = []
              allstories = XML2JSON.parse(data, true)
              stories = allstories.stories.story if allstories.stories? && allstories.stories.story?
              stories = [stories] if stories.constructor != Array
              if stories? && stories.length > 0
                normalize_stories = (PivotalRocketBackground.normalize_story_for_saving(story) for story in stories)
                PivotalRocketStorage.set_stories(project, normalize_stories, selected_type_bol)
              else
                PivotalRocketStorage.delete_stories(project, selected_type_bol)
              PivotalRocketBackground.init_list_stories()
              
          pivotal_lib.get_stories_by_bool(params, selected_type_bol)
        error: (jqXHR, textStatus, errorThrown) ->
          story = PivotalRocketStorage.find_story(project_id, story_id, selected_type_bol)
          if story?
            PivotalRocketBackground.popup.$('#storyInfo').find("select.change_story_state[data-story-id=#{story_id}]").val(story.current_state)
  # normalize story
  normalize_story_for_saving: (story) ->
    # normalize notes
    if story.notes?
      if story.notes.note?
        if story.notes.note.constructor != Array
          story.notes = [story.notes.note]
        else
          story.notes = story.notes.note
      else
        story.notes = [story.notes] if story.notes.constructor != Array
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
        task.complete = if "true" == task.complete then true else false
        task.project_id = story.project_id
        task.story_id = story.id
        task
        
    if !story.estimate? || (story.estimate? && -1 == parseInt(story.estimate))
      story.estimate_text = "Unestimated"
    else
      story.estimate_text = "#{story.estimate} points"
        
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
    username = PivotalRocketBackground.popup.$('#loginUsername').val()
    password = PivotalRocketBackground.popup.$('#loginPassword').val()
    if username? && password?
      pivotal_auth_lib = new PivotalAuthLib
        username: username
        password: password
        success: (data, textStatus, jqXHR) ->
          account = XML2JSON.parse(data, true)
          account = account.person if account.person?
          company_name = PivotalRocketBackground.popup.$('#loginCompanyName').val()
          account.company_name = company_name if company_name.length > 0
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

$ ->
  PivotalRocketBackground.init()