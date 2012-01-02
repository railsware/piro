root = global ? window

root.PivotalRocketStorage = 
  accounts: null
  
  set: (key, json) ->
    window.localStorage.setItem(key, JSON.stringify(json))
    json
  get: (key) ->
    str_data = window.localStorage.getItem(key)
    json_data = if str_data? then JSON.parse(str_data) else null
    json_data
    
  get_accounts: ->
    if !PivotalRocketStorage.accounts?
      PivotalRocketStorage.accounts = PivotalRocketStorage.get("accounts")
      PivotalRocketStorage.accounts ||= []
    PivotalRocketStorage.accounts
    
  set_accounts: (accounts) ->
    PivotalRocketStorage.set("accounts", accounts)
    PivotalRocketStorage.accounts = accounts
    
  set_projects: (account, projects) ->
    PivotalRocketStorage.set("projects_" + account.id, projects)
    
  get_projects: (account) ->
    PivotalRocketStorage.get("projects_" + account.id)
    
  set_stories: (project, stories, requester = false) ->
    key = if requester then ("stories_" + project.id) else ("requester_stories_" + project.id)
    PivotalRocketStorage.set(key, stories)
    
  set_stories_by_project_id: (project_id, stories, requester = false) ->
    key = if requester then ("stories_" + project_id) else ("requester_stories_" + project_id)
    PivotalRocketStorage.set(key, stories)

  get_stories: (project, requester = false) ->
    key = if requester then ("stories_" + project.id) else ("requester_stories_" + project.id)
    PivotalRocketStorage.get(key)
    
  get_status_stories: (project, requester = false) ->
    stories = PivotalRocketStorage.get_stories(project, requester)
    if stories?
      current_stories = []
      done_stories = []
      icebox_stories = []
      for story in stories
        if "unscheduled" == story.current_state
          icebox_stories.push(story)
        else if "accepted" == story.current_state
          done_stories.push(story)
        else
          current_stories.push(story)
    
      return {current: current_stories, done: done_stories, icebox: icebox_stories}
    else
      return null