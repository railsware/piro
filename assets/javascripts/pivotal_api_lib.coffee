root = global ? window

class root.PivotalApiLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (@account) ->
    # constructor
    
  get_projects: (params) =>
    $.ajax
      #setup
      timeout: 80000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects"
      success: params.success
      error: params.error
  
  get_stories_for_project: (params) =>
    url_params = encodeURIComponent("owner:" + @account.initials)
    url_params = encodeURIComponent("requester:" + @account.initials) if params.requester? && params.requester is true
    
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project.id}/stories?filter=" + url_params
      success: (data, textStatus, jqXHR) ->
        if params? && params.success?
          params.success(data, textStatus, jqXHR, params.project)
      error: params.error
      complete: params.complete
      beforeSend: params.beforeSend
      
  update_account: =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/me"
      success: (data, textStatus, jqXHR) =>
        account = XML2JSON.parse(data, true)
        account = account.person if account.person?
        if account.email?
          accounts = PivotalRocketStorage.get_accounts()
          new_accounts = for one_account in accounts
            if one_account.email?
              if one_account.email == account.email
                account
              else
                one_account
          PivotalRocketStorage.set_accounts(new_accounts)

  get_story: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}"
      type: "GET"
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete

  add_story: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      # using v3, because v4 broken
      url: "https://www.pivotaltracker.com/services/v3/projects/#{params.project_id}/stories"
      type: "POST"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete
  
  update_story: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}"
      type: "PUT"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete
  
  add_task: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/tasks"
      type: "POST"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete
      
  update_task: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/tasks/#{params.task_id}"
      type: "PUT"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete

  delete_task: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/tasks/#{params.task_id}"
      type: "DELETE"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete

  add_comment: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/comments"
      type: "POST"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete

  delete_comment: (params) =>
    $.ajax
      #setup
      timeout: 40000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project_id}/stories/#{params.story_id}/comments/#{params.comment_id}"
      type: "DELETE"
      data: params.data
      success: params.success
      error: params.error
      beforeSend: params.beforeSend
      complete: params.complete
        
  get_activities: (params) =>
    formated_date = this.formated_date(params.from_date)
    $.ajax
      #setup
      timeout: 20000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/activities?limit=100&occurred_since_date=" + encodeURIComponent(formated_date)
      success: params.success
    
  formated_date: (date) =>
    return "#{date.getFullYear()}/#{date.getMonth() + 1}/#{date.getDate()} #{date.getHours()}:#{date.getMinutes()}:00"
 
 
 
# pivotal auth lib   
class root.PivotalAuthLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (params) ->
    if params.username? && params.password?
      $.ajax
        cache: false
        global: false
        dataType: 'xml' 
        url: "#{this.baseUrl}/me"
        username: params.username
        password: params.password
        success: params.success
        error: params.error
        beforeSend: params.beforeSend
    else
      $.ajax
        cache: false
        global: false
        dataType: 'xml' 
        url: "#{this.baseUrl}/me"
        headers:
          "X-TrackerToken": params.token
        success: params.success
        error: params.error
        beforeSend: params.beforeSend