root = global ? window

class root.PivotalApiLib
  constructor: (@account) ->
    # constructor
    $.ajaxSetup
      timeout: 60000
      crossDomain: true
      dataType: 'xml'
      headers:
        "X-TrackerToken": @account.token.guid
    
  get_projects: (params) =>
    $.ajax
      url: "https://www.pivotaltracker.com/services/v4/projects"
      success: params.success
      error: params.error
    
  get_stories_for_project: (params) =>
    $.ajax
      url: "http://www.pivotaltracker.com/services/v4/projects/" + params.project.id + "/stories?filter=" + encodeURIComponent("owner:" + @account.initials)
      success: (data, textStatus, jqXHR) ->
        if params? && params.success?
          params.success(data, textStatus, jqXHR, params.project)
      error: params.error
      complete: params.complete
      
  get_stories_for_project_requester: (params) =>
    $.ajax
      url: "http://www.pivotaltracker.com/services/v4/projects/" + params.project.id + "/stories?filter=" + encodeURIComponent("requester:" + @account.initials)
      success: (data, textStatus, jqXHR) ->
        if params? && params.success?
          params.success(data, textStatus, jqXHR, params.project)
      error: params.error
      complete: params.complete
      
  update_account: =>
    $.ajax
      url: "https://www.pivotaltracker.com/services/v4/me"
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
    
 
 
 
# pivotal auth lib   
class root.PivotalAuthLib
  constructor: (params) ->      
    $.ajax
      cache: false
      global: false
      dataType: 'xml'
      headers: 
        "X-TrackerToken": null 
      url: "https://www.pivotaltracker.com/services/v4/me"
      username: params.username
      password: params.password
      success: params.success
      error: params.error