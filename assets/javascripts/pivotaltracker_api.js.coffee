root = global ? window

class root.PivotaltrackerApi
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (@account) ->
    # constructor
  sendPivotalRequest: (params) =>
    ajaxParams = 
      timeout: 80000
      crossDomain: true
      dataType: 'xml'
      headers: 
        "X-TrackerToken": @account.token.guid
    ajaxParams.url         = params.url if params.url?
    ajaxParams.type        = params.type if params.type?
    ajaxParams.data        = params.data if params.data?
    ajaxParams.error       = params.error if params.error?
    ajaxParams.success     = params.success if params.success?
    ajaxParams.complete    = params.complete if params.complete?
    ajaxParams.beforeSend  = params.beforeSend if params.beforeSend?
    $.ajax ajaxParams
    
  getProjects: (params) =>
    successFunction = params.success
    params.url = "#{this.baseUrl}/projects"
    params.success = (data, textStatus, jqXHR) =>
      successFunction(data, textStatus, jqXHR)
    this.sendPivotalRequest(params)
  
# pivotal auth lib
class root.PivotaltrackerAuthLib
  baseUrl: "https://www.pivotaltracker.com/services/v4"
  constructor: (params) ->
    ajaxParams = 
      cache: false
      global: false
      dataType: 'xml' 
      url: "#{this.baseUrl}/me"
      success: (data, textStatus, jqXHR) ->
        template = [ "//person", 
        { id: "id", email: "email", name: "name", initials: "initials", 
        "token": {id: "token/id", guid: "token/guid"}, 
        "time_zone": {name: "time_zone/name", code: "time_zone/code", offset: "time_zone/offset"}
        }]
        persons = Jath.parse(template, data)
        person = if persons? && persons.length > 0 then persons[0] else null
        params.success(person, textStatus, jqXHR) if params.success?
      error: params.error
      beforeSend: params.beforeSend
    if params.username? && params.password?
      ajaxParams.username = params.username
      ajaxParams.password = params.password
      ajaxParams.headers = 
        'Authorization': "Basic #{btoa(params.username + ":" + params.password)}"
    else
      ajaxParams.headers = 
        "X-TrackerToken": (params.token || null)
    $.ajax ajaxParams