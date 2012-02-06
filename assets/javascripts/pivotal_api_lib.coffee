root = global ? window

class root.PivotalApiLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (@account) ->
    # constructor
  get_projects: (params) =>
    $.ajax
      #setup
      timeout: 60000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects"
      success: params.success
      error: params.error
    
  get_stories_for_project: (params) =>
    $.ajax
      #setup
      timeout: 60000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project.id}/stories?filter=" + encodeURIComponent("owner:" + @account.initials)
      success: (data, textStatus, jqXHR) ->
        if params? && params.success?
          params.success(data, textStatus, jqXHR, params.project)
      error: params.error
      complete: params.complete
      
  get_stories_for_project_requester: (params) =>
    $.ajax
      #setup
      timeout: 60000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/projects/#{params.project.id}/stories?filter=" + encodeURIComponent("requester:" + @account.initials)
      success: (data, textStatus, jqXHR) ->
        if params? && params.success?
          params.success(data, textStatus, jqXHR, params.project)
      error: params.error
      complete: params.complete
      
  update_account: =>
    $.ajax
      #setup
      timeout: 60000
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
  
  update_story: (params) =>
    $.ajax
      #setup
      timeout: 60000
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
        
  get_activities: (date = new Date()) =>
    formated_date = this.formated_date(date)
    $.ajax
      #setup
      timeout: 60000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
      # else
      url: "#{this.baseUrl}/activities?limit=100&occurred_since_date=" + encodeURIComponent(formated_date)
      success: (data, textStatus, jqXHR) =>
        activities = XML2JSON.parse(data, true)
        console.debug activities
    
  formated_date: (date) =>
    return "#{date.getFullYear()}/#{date.getMonth() + 1}/#{date.getDate()} #{date.getHours()}:#{date.getMinutes()}:00"
 
 
 
# pivotal auth lib   
class root.PivotalAuthLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (params) ->      
    $.ajax
      cache: false
      global: false
      dataType: 'xml'
      headers: 
        "X-TrackerToken": null 
      url: "#{this.baseUrl}/me"
      username: params.username
      password: params.password
      success: params.success
      error: params.error
      beforeSend: params.beforeSend