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
  delete_by_key: (key) ->
    window.localStorage.removeItem(key)
    
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
    update_interval = PivotalRocketStorage.get('update_interval')
    update_interval = 10 if !update_interval?
    update_interval
