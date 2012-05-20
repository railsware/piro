root = global ? window

class root.PivotalApiLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (@account) ->
    # constructor
  send_pivotal_request: (params) =>
    ajax_params = 
      timeout: 80000
      crossDomain: true
      dataType: 'xml'
      headers: 
        "X-TrackerToken": @account.token.guid
    ajax_params.url         = params.url if params.url?
    ajax_params.type        = params.type if params.type?
    ajax_params.data        = params.data if params.data?
    ajax_params.error       = params.error if params.error?
    ajax_params.success     = params.success if params.success?
    ajax_params.complete    = params.complete if params.complete?
    ajax_params.beforeSend  = params.beforeSend if params.beforeSend?
    $.ajax ajax_params
  get_projects: (params) =>
    params.url = "#{this.baseUrl}/projects"
    this.send_pivotal_request(params)
  
  get_stories_for_project: (params) =>
    url_params = encodeURIComponent("owner:#{@account.initials}")
    url_params = encodeURIComponent("requester:#{@account.initials}") if params.requester? && params.requester is true
    params.url = "#{this.baseUrl}/projects/#{params.project.id}/stories?filter=#{url_params}"
    if params.success?
      params.success_function = params.success
      params.success = (data, textStatus, jqXHR) ->
        params.success_function(data, textStatus, jqXHR, params.project)
    
    this.send_pivotal_request(params)
      
  update_account: =>
    params.url = "#{this.baseUrl}/me"
    params.success = (data, textStatus, jqXHR) ->
      account = XML2JSON.parse(data, true)
      account = account.person if account.person?
      return false unless account.email?
      accounts = PivotalRocketStorage.get_accounts()
      new_accounts = for one_account in accounts
        if one_account.email? && one_account.email == account.email
          account
        else
          one_account
      PivotalRocketStorage.set_accounts(new_accounts)
    this.send_pivotal_request(params)

  get_story: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}"
    params.type = "GET"
    this.send_pivotal_request(params)

  add_story: (params) =>
    # using v3, because v4 broken (http://community.pivotaltracker.com/pivotal/topics/create_story_error_by_api)
    #params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories"
    params.url = "https://www.pivotaltracker.com/services/v3/projects/#{params.project_id}/stories"
    params.type = "POST"
    this.send_pivotal_request(params)
  
  update_story: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}"
    params.type = "PUT"
    this.send_pivotal_request(params)
  
  add_task: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/tasks"
    params.type = "POST"
    this.send_pivotal_request(params)
      
  update_task: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/tasks/#{params.task_id}"
    params.type = "PUT"
    this.send_pivotal_request(params)

  delete_task: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/tasks/#{params.task_id}"
    params.type = "DELETE"
    this.send_pivotal_request(params)

  add_comment: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/comments"
    params.type = "POST"
    this.send_pivotal_request(params)

  delete_comment: (params) =>
    params.url = "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/comments/#{params.comment_id}"
    params.type = "DELETE"
    this.send_pivotal_request(params) 
 
 
# pivotal auth lib
class root.PivotalAuthLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (params) ->
    ajax_params = 
      cache: false
      global: false
      dataType: 'xml' 
      url: "#{this.baseUrl}/me"
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
    if params.username? && params.password?
      ajax_params.username = params.username
      ajax_params.password = params.password
      ajax_params.headers = 
        'Authorization': "Basic #{btoa(params.username + ":" + params.password)}"
    else
      ajax_params.headers = 
        "X-TrackerToken": (params.token || null)
    $.ajax ajax_params