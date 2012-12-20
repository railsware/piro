class PiroPopup.Views.OptionsAccount extends Backbone.View
  tagName: "li"
  template: SHT['options/account']
  events:
    "click .account_edit_link"            : "editAccountLink"
    "click .account_delete_link"          : "deleteAccountLink"
    "submit .edit_account_form"           : "editAccount"
    "click .cancel_edit_account_link"     : "cancelEditAccount"
    "click .confirm_delete_account_link"  : "confirmDeleteAccount"
    "click .cancel_delete_account_link"   : "cancelDeleteAccount"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-account-id", @model.get('id'))
    this

  remove: =>
    $(@el).remove()
    
  editAccount: (e) =>
    e.preventDefault()
    if @$('input.edit_account_company').val().length > 0
      account = _.extend(@model.toJSON(), {company: @$('input.edit_account_company').val()})
    else
      account = @model.toJSON()
      delete account.company if account.company?
    PiroOptions.db.saveAccountAndGetAll account, 
      success: (accounts) =>
        @model.unset("company") unless account.company?
        @model.set(account)
        PiroOptions.cleanupPopupViews()

  confirmDeleteAccount: (e) =>
    e.preventDefault()
    PiroOptions.db.deleteAccount @model.get('id'), 
      success: =>
        @model.trigger('destroy', @model, @model.collection, {})
        PiroOptions.cleanupPopupViews()

  editAccountLink: (e) =>
    e.preventDefault()
    @$('.box_item').removeClass('deleting').addClass('editing')
    @$('.edit_account_company').focus()

  deleteAccountLink: (e) =>
    e.preventDefault()
    @$('.box_item').removeClass('editing').addClass('deleting')

  cancelEditAccount: (e) =>
    e.preventDefault()
    @$('.box_item').removeClass('editing')

  cancelDeleteAccount: (e) =>
    e.preventDefault()
    @$('.box_item').removeClass('deleting')

  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove
