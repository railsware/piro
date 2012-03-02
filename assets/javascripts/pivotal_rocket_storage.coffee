root = global ? window

root.PivotalRocketStorage = 
  
  set: (key, json) ->
    window.localStorage.setItem(key, JSON.stringify(json))
    json
  get: (key) ->
    str_data = window.localStorage.getItem(key)
    json_data = if str_data? then JSON.parse(str_data) else null
    json_data
  delete_by_key: (key) ->
    window.localStorage.removeItem(key)
    
  get_user_options: ->
    PivotalRocketStorage.get("user_options") || {user_role: "owner", tasks_filter: null, opened_task_box: false, opened_comment_box: false}

  set_user_options: (option) ->
    PivotalRocketStorage.set("user_options", option)
  
  get_role: ->
    PivotalRocketStorage.get_user_options().user_role
    
  set_role: (value) ->
    user_options = PivotalRocketStorage.get_user_options()
    user_options.user_role = value
    PivotalRocketStorage.set_user_options(user_options)
    
  get_opened_by_type: (key) ->
    PivotalRocketStorage.get_user_options()[key]

  set_opened_by_type: (key, value) ->
    user_options = PivotalRocketStorage.get_user_options()
    user_options[key] = value
    PivotalRocketStorage.set_user_options(user_options)

  get_tasks_filter: ->
    PivotalRocketStorage.get_user_options().tasks_filter

  set_tasks_filter: (value) ->
    user_options = PivotalRocketStorage.get_user_options()
    user_options.tasks_filter = value
    PivotalRocketStorage.set_user_options(user_options)
    
  get_accounts: ->
    PivotalRocketStorage.get("accounts") || []
    
  find_account: (account_id) ->
    for account in PivotalRocketStorage.get_accounts()
      return account if parseInt(account.id) == parseInt(account_id)
    return null
    
  save_account: (account) ->
    is_pushed = false
    new_accounts = for one_account in PivotalRocketStorage.get_accounts()
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
    
  set_accounts: (accounts) ->
    PivotalRocketStorage.set("accounts", accounts)
    
  sort_accounts: (account_ids) ->
    new_account_list = []
    for id in account_ids
      account = PivotalRocketStorage.find_account(id)
      new_account_list.push(account) if account?
    PivotalRocketStorage.set_accounts(new_account_list)
    
  delete_account: (account_id) ->
    del_account = PivotalRocketStorage.find_account(account_id)
    projects = PivotalRocketStorage.get_projects(del_account)
    if projects?
      for project in projects
        PivotalRocketStorage.delete_stories(project)
        PivotalRocketStorage.delete_stories(project, true)
    PivotalRocketStorage.delete_project(del_account)
    new_accounts = []
    for account in PivotalRocketStorage.get_accounts()
      if account.id?
        new_accounts.push(account) if parseInt(account.id) != parseInt(del_account.id)
    PivotalRocketStorage.set_accounts(new_accounts)
    
  set_projects: (account, projects) ->
    projects = for project in projects
      # normalize memberships in project
      if project.memberships?
        if project.memberships.membership?
          if project.memberships.membership.constructor != Array
            project.memberships = [project.memberships.membership]
          else
            project.memberships = project.memberships.membership
        else
          project.memberships = [project.memberships] if project.memberships.constructor != Array
          
      if !project.view_conditions?
        old_project = PivotalRocketStorage.find_project(account, project.id)
        project.view_conditions = if old_project? && old_project.view_conditions? then old_project.view_conditions else {} 
      project
    # sorting
    old_projects = PivotalRocketStorage.get_projects(account)
    if old_projects? && old_projects.length > 0
      project_ids = (old_project.id for old_project in old_projects)
      projects = PivotalRocketStorage.sort_projects_by_ids(projects, project_ids)
    PivotalRocketStorage.set("projects_" + account.id, projects)
  
  sort_projects: (account, project_ids) ->
    projects = PivotalRocketStorage.get_projects(account)
    if projects? && project_ids?
      sorted_projects = PivotalRocketStorage.sort_projects_by_ids(projects, project_ids)
      PivotalRocketStorage.set("projects_" + account.id, sorted_projects)
  
  sort_projects_by_ids: (projects, ids) ->
    sorted_hash = {}
    for project_id, project_sort in ids
      sorted_hash[parseInt(project_id)] = project_sort
    projects.sort (a,b) ->
      a_order = sorted_hash[parseInt(a.id)]
      a_order = jQuery.inArray(a, projects) if !a_order?
      a_order = projects.length if -1 == a_order
      b_order = sorted_hash[parseInt(b.id)]
      b_order = jQuery.inArray(b, projects) if !b_order?
      b_order = projects.length if -1 == b_order
      a_order - b_order
    projects
    
  find_project: (account, project_id) ->
    projects = PivotalRocketStorage.get_projects(account)
    if projects?
      for project in projects
        return project if parseInt(project.id) == parseInt(project_id)
    return null
  
  update_project: (account, new_project) ->
    projects = PivotalRocketStorage.get_projects(account)
    if projects?
      updated_projects = for project in projects
        if parseInt(new_project.id) == parseInt(project.id) then new_project else project
      PivotalRocketStorage.set("projects_" + account.id, updated_projects)
  
  set_options_for_project: (project, options) ->
    if project? && options?
      for option_key, option_value of options
        switch option_key
          when "hide_project_cell"
            if option_value is true
              project.view_conditions[option_key] = true
            else
              delete project.view_conditions[option_key]
          else
            project.view_conditions[option_key] = option_value
    # ret project
    return project
    
  update_view_options_in_project: (account, project_id, new_options) ->
    project = PivotalRocketStorage.find_project(account, project_id)
    if new_options? && project?
      project = PivotalRocketStorage.set_options_for_project(project, new_options)
      PivotalRocketStorage.update_project(account, project)
    return true
    
  update_view_options_all_in_projects: (account, new_options) ->
    projects = PivotalRocketStorage.get_projects(account)
    updated_projects = for project in projects
      PivotalRocketStorage.set_options_for_project(project, new_options)
    PivotalRocketStorage.set("projects_" + account.id, updated_projects)
    
  get_projects: (account) ->
    PivotalRocketStorage.get("projects_" + account.id)
  
  delete_project: (account) ->
    PivotalRocketStorage.delete_by_key("projects_" + account.id)
    
  set_stories: (project, stories, requester = false) ->
    key = if requester then ("stories_" + project.id) else ("requester_stories_" + project.id)
    PivotalRocketStorage.set(key, stories)
  
  get_stories: (project, requester = false) ->
    key = if requester then ("stories_" + project.id) else ("requester_stories_" + project.id)
    PivotalRocketStorage.get(key)
    
  delete_stories: (project, requester = false) ->
    key = if requester then ("stories_" + project.id) else ("requester_stories_" + project.id)
    PivotalRocketStorage.delete_by_key(key)
    
  get_status_stories: (project, requester = false, search_text = null) ->
    stories = PivotalRocketStorage.get_stories(project, requester)
    if stories?
      current_stories = []
      done_stories = []
      icebox_stories = []
      for story in stories
        res_story = story
        if search_text?
          res_story = PivotalRocketStorage.search_by_story(res_story, search_text)
        if res_story?  
          if "unscheduled" == res_story.current_state
            res_story.box_class = "icebox"
            icebox_stories.push(res_story)
          else if "accepted" == res_story.current_state
            res_story.box_class = "done"
            done_stories.push(res_story)
          else
            res_story.box_class = "current"
            current_stories.push(res_story)
    
      return {current: current_stories, done: done_stories, icebox: icebox_stories}
    else
      return null
      
  search_by_story: (story, search_text) ->
    if search_text.length > 0 && "#" == search_text[0]
      search = new RegExp(search_text.substr(1), "gi")
      if story.labels? && story.labels.length > 0
        return story if story.labels.match(search)? && story.labels.match(search).length > 0
      return null
    else
      search = new RegExp(search_text, "gi")
      if story.id? && story.id.length > 0
        return story if story.id.match(search)? && story.id.match(search).length > 0
      if story.name? && story.name.length > 0
        return story if story.name.match(search)? && story.name.match(search).length > 0
      if story.description? && story.description.length > 0
        return story if story.description.match(search)? && story.description.match(search).length > 0
      if story.current_state? && story.current_state.length > 0
        return story if story.current_state.match(search)? && story.current_state.match(search).length > 0
    return null
      
  find_story: (project_id, story_id, requester = false) ->
    key = if requester then ("stories_" + project_id) else ("requester_stories_" + project_id)
    stories = PivotalRocketStorage.get(key)
    if stories?
      for story in stories
        return story if parseInt(story.id) == parseInt(story_id)
    return null

  get_update_interval: ->
    PivotalRocketStorage.get('update_interval') || 10
  set_update_interval: (interval) ->
    value = parseInt(interval)
    value = 10 if value < 10
    value = 360 if value > 360
    PivotalRocketStorage.set('update_interval', value)
    value
  
  get_fullscreen_mode: ->
    PivotalRocketStorage.get('fullscreen_mode') || false
  set_fullscreen_mode: (value) ->
    PivotalRocketStorage.set('fullscreen_mode', value)