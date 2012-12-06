class PiroPopup.Views.StoriesSmartElement extends PiroPopup.Views.StoriesElement
  showStoryInfo: (e) =>
    e.preventDefault()
    Backbone.history.navigate("smart_story/#{@model.get("id")}", {trigger: true, replace: true})