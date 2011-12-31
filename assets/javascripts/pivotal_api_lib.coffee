class window.PivotalApiLib
  constructor: (@account) ->
  
  first_sync: ->
    
    
 
 
 
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
        account = $.xml2json(data)
        if account.email?
          accounts = PivotalRocketStorage.get_accounts()
          is_pushed = false
          new_accounts = for one_account in accounts
            if one_account.email?
              if one_account.email == account.email
                is_pushed = true
                account
              else
                one_account
                
          if is_pushed is false
            new_accounts.push(account)
          
          PivotalRocketStorage.set_accounts(new_accounts)
          pivotal_api_obj = new PivotalApiLib account
          pivotal_api_obj.first_sync
      error: (jqXHR, textStatus, errorThrown) ->
        console.debug jqXHR
        console.debug textStatus
        console.debug errorThrown
        