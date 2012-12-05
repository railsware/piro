class PiroPopup.Views.StoriesElement extends Backbone.View
  tagName: "li"
  className: "story_element"
  template: SHT['stories/element']
  events:
    "click .story_link_info"          : "showStoryInfo"
    "click .story_label"              : "filterByLabel"
    "click .story_owned_by"           : "filterByOwner"
    "click .change_status_button"     : "changeStoryStatus"
  
  initialize: =>
    @model.on 'change', @render
    @model.on 'destroy', @remove

  render: =>
    $(@el).html(@template.render(@model.toJSON()))
    $(@el).attr("data-story-id", @model.get('id'))
    this
    
  showStoryInfo: (e) =>
    e.preventDefault()
    Backbone.history.navigate("story/#{@model.get("id")}", {trigger: true, replace: true})

  filterByLabel: (e) =>
    e.preventDefault()
    e.stopPropagation()
    PiroPopup.globalEvents.trigger "filter:stories", "##{$(e.currentTarget).text()}"

  filterByOwner: (e) =>
    e.preventDefault()
    e.stopPropagation()
    PiroPopup.globalEvents.trigger "filter:stories", "@#{$(e.currentTarget).text()}"

  changeStoryStatus: (e) =>
    e.preventDefault()
    newStatus = @$(e.currentTarget).data('status')
    attributes = 
      story:
        current_state: newStatus
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      PiroPopup.bgPage.PiroBackground.updateAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(),
        @model.toJSON(),
        attributes,
        beforeSend: =>
          @$(e.currentTarget).attr('disabled', 'disabled')
        success: (story) =>
          @model.set(story)
          PiroPopup.globalEvents.trigger "story::change::attributes", @model
        error: @render
      )

  remove: =>
    $(@el).remove()
    
  onDestroyView: =>
    @model.off 'change', @render
    @model.off 'destroy', @remove