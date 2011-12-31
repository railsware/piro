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
        account = $.xml2json(data)
        if account.token? && account.token.guid?
          accounts = PivotalRocketStorage.get_accounts()
          is_pushed = false
          new_accounts = for one_account in accounts
            if one_account.token? && one_account.token.guid?
              if one_account.token.guid == account.token.guid
                is_pushed = true
                account
              else
                one_account
                
          if is_pushed is false
            new_accounts.push(account)
          
          PivotalRocketStorage.set_accounts(new_accounts)
      error: (jqXHR, textStatus, errorThrown) ->
        console.debug jqXHR
        console.debug textStatus
        console.debug errorThrown
        

$ ->
  data = new PivotalAuthLib "leopard", "monkeydev"