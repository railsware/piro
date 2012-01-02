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
  
  init: ->
    if PivotalRocketStorage.get_accounts().length > 0
      PivotalRocketBackground.account = PivotalRocketStorage.get_accounts()[0]
      PivotalRocketBackground.initial_sync()
  
  load_popup_view: ->
    chrome.extension.getViews({type:"popup"})[0]
  
  init_popup: ->
    PivotalRocketBackground.popup = PivotalRocketBackground.load_popup_view() if !PivotalRocketBackground.popup?
    if PivotalRocketBackground.popup?
      PivotalRocketBackground.init_spinner(PivotalRocketBackground.is_loading)
      PivotalRocketBackground.init_bindings()
      if PivotalRocketStorage.get_accounts().length > 0
        PivotalRocketBackground.init_list_stories()
        PivotalRocketBackground.popup.$('#loginPage').hide()
        PivotalRocketBackground.popup.$('#mainPage').show()
      else
        PivotalRocketBackground.popup.$('#mainPage').hide()
        PivotalRocketBackground.popup.$('#loginPage').show()
  
  init_bindings: ->
    PivotalRocketBackground.popup.$('#storiesTabs').tabs()
    # login  
    PivotalRocketBackground.popup.$('#login_button').click (event) =>
      username = PivotalRocketBackground.popup.$('#login_username').val()
      password = PivotalRocketBackground.popup.$('#login_password').val()
      PivotalRocketBackground.login_by_user(username, password)
    
    # update link        
    PivotalRocketBackground.popup.$('#updateStories').click (event) =>
      PivotalRocketBackground.is_loading = true
      PivotalRocketBackground.init_spinner(PivotalRocketBackground.is_loading)
      PivotalRocketBackground.initial_sync()
  
  init_spinner: (loading = false) ->
    template = PivotalRocketBackground.popup.$('#spinner_template').html()
    if template.length > 0
      compiledTemplate = Hogan.compile(template)
      hash_data = {
        update_msg: chrome.i18n.getMessage("update_stories_link")
      }
      if loading
        hash_data.is_loading = {
          loading_msg: chrome.i18n.getMessage("loading_msg")
        }
      
      PivotalRocketBackground.popup.$('#loaderSpinner').html(compiledTemplate.render(hash_data))
  
  init_list_stories: ->
    template = PivotalRocketBackground.popup.$('#project_cell').html()
    if template.length > 0
      compiledTemplate = Hogan.compile(template)
      stories_list = {current: [], done: [], icebox: []}
      stories_count = {current: 0, done: 0, icebox: 0}
      stored_projects = PivotalRocketStorage.get_projects(PivotalRocketBackground.account)
      for project in stored_projects
        stored_stories = PivotalRocketStorage.get_status_stories(project)
        if stored_stories?
          if stored_stories.current? && stored_stories.current.length > 0
            project.stories = stored_stories.current
            stories_count.current += stored_stories.current.length
            stories_list.current.push(compiledTemplate.render(project))
          if stored_stories.done? && stored_stories.done.length > 0
            project.stories = stored_stories.done
            stories_count.done += stored_stories.done.length
            stories_list.done.push(compiledTemplate.render(project))
          if stored_stories.icebox? && stored_stories.icebox.length > 0
            project.stories = stored_stories.icebox
            stories_count.icebox += stored_stories.icebox.length
            stories_list.icebox.push(compiledTemplate.render(project))
      
      no_stories_msg = "<li class='empty'>#{chrome.i18n.getMessage("no_stories_msg")}</li>"
      
      PivotalRocketBackground.popup.$('#currentTabLabel').text("#{chrome.i18n.getMessage("current_stories_tab")} (#{stories_count.current.toString()})")
      if stories_count.current > 0
        PivotalRocketBackground.popup.$('#currentStoriesList').html(stories_list.current.join(""))
      else
        PivotalRocketBackground.popup.$('#currentStoriesList').html(no_stories_msg)
      PivotalRocketBackground.popup.$('#doneTabLabel').text("#{chrome.i18n.getMessage("done_stories_tab")} (#{stories_count.done.toString()})")
      if stories_count.done > 0
        PivotalRocketBackground.popup.$('#doneStoriesList').html(stories_list.done.join(""))
      else
        PivotalRocketBackground.popup.$('#doneStoriesList').html(no_stories_msg)
      PivotalRocketBackground.popup.$('#iceboxTabLabel').text("#{chrome.i18n.getMessage("icebox_stories_tab")} (#{stories_count.icebox.toString()})")
      if stories_count.icebox > 0
        PivotalRocketBackground.popup.$('#iceboxStoriesList').html(stories_list.icebox.join(""))
      else
        PivotalRocketBackground.popup.$('#iceboxStoriesList').html(no_stories_msg)
  
  initial_sync: ->
    PivotalRocketBackground.pivotal_api_lib = new PivotalApiLib(PivotalRocketBackground.account)
    PivotalRocketBackground.pivotal_api_lib.get_projects
      success: (data, textStatus, jqXHR) ->
        allprojects = XML2JSON.parse(data, true)
        projects = []
        projects = allprojects.projects.project if allprojects.projects? && allprojects.projects.project?
        projects = [projects] if projects.constructor != Array
        PivotalRocketStorage.set_projects(PivotalRocketBackground.account, projects)
        PivotalRocketBackground.tmp_counter = projects.length
        for project in projects
          PivotalRocketBackground.pivotal_api_lib.get_stories_for_project
            project: project
            complete: (jqXHR, textStatus) ->
              PivotalRocketBackground.tmp_counter -= 1
              if PivotalRocketBackground.tmp_counter <= 0
                PivotalRocketBackground.is_loading = false
                PivotalRocketBackground.init_spinner(PivotalRocketBackground.is_loading)
            success: (data, textStatus, jqXHR) ->
              stories = []
              allstories = XML2JSON.parse(data, true)
              stories = allstories.stories.story if allstories.stories? && allstories.stories.story?
              stories = [stories] if stories.constructor != Array
              PivotalRocketStorage.set_stories_by_project_id(stories[0].project_id, stories) if stories.length > 0
            error: (jqXHR, textStatus, errorThrown) ->
              # error
            
      error: (jqXHR, textStatus, errorThrown) ->
        # error
                
  save_account: (account) ->
    if account.email?
      accounts = PivotalRocketStorage.get_accounts()
      is_pushed = false
      new_accounts = for one_account in accounts
        if one_account.email?
          if one_account.email == account.email
            is_pushed = true
            account
          else
            one_account
      if is_pushed is false
        new_accounts.push(account)
      PivotalRocketStorage.set_accounts(new_accounts)
      account
  
  login_by_user: (username, password) ->
    if username? && password?
      pivotal_auth_lib = new PivotalAuthLib
        username: username
        password: password
        success: (data, textStatus, jqXHR) ->
          account = XML2JSON.parse(data, true)
          account = account.person if account.person?
          PivotalRocketBackground.account = PivotalRocketBackground.save_account(account)
          PivotalRocketBackground.initial_sync()
          
        error: (jqXHR, textStatus, errorThrown) ->
          # error


$ ->
  PivotalRocketBackground.init()