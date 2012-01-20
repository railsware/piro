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
    PivotalRocketStorage.set("projects_" + account.id, projects)
    
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
    
  get_status_stories: (project, requester = false) ->
    stories = PivotalRocketStorage.get_stories(project, requester)
    if stories?
      current_stories = []
      done_stories = []
      icebox_stories = []
      for story in stories
        if "unscheduled" == story.current_state
          story.box_class = "icebox"
          icebox_stories.push(story)
        else if "accepted" == story.current_state
          story.box_class = "done"
          done_stories.push(story)
        else
          story.box_class = "current"
          current_stories.push(story)
    
      return {current: current_stories, done: done_stories, icebox: icebox_stories}
    else
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
