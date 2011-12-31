class window.PivotalApiLib
  constructor: ->
    console.log "init"
 
 
 
# pivotal auth lib   
class window.PivotalAuthLib
  constructor: (username, password) ->
    $.ajax
      url: "https://www.pivotaltracker.com/services/v4/me"
      crossDomain: true
      dataType: "xml"
      username: username
      password: password
      success: (data, textStatus, jqXHR) ->
        console.debug data
        console.debug $.xml2json(data)
      error: (jqXHR, textStatus, errorThrown) ->
        console.debug jqXHR
        console.debug textStatus
        console.debug errorThrown
        
