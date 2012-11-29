class PiroPopup.Views.StoriesForm extends Backbone.View
  tagName: "div"
  template: SHT['stories/form']
  events:
    "change .add_story_project_id"      : "changeProject"
    "change .add_story_story_type"      : "changeStoryType"
    "click .story_owner_id_to_me"       : "selectOwnedByMe"
    "submit .add_story_form"            : "submitStory"
  
  initialize: =>

  render: =>
    projects = PiroPopup.pivotalProjects.toJSON().sort (a, b) ->
      if a.name? && b.name?
        return -1 if (a.name < b.name)
        return 1 if (a.name > b.name)
      return 0
    $(@el).html(@template.render(
      projects: projects
    ))
    # set default project
    @$('.add_story_project_id').val(PiroPopup.db.getLatestProjectIdLS()).trigger("liszt:updated")
    # controls
    @initControlls()
    @initStoryType()
    @initCalendar()
    @setStoryTmpTitle()
    this
  
  changeProject: (e) =>
    @initControlls()
    
  changeStoryType: (e) =>
    @initStoryType()
    
  initCalendar: =>
    @$('.add_story_release_date').datepicker
      changeMonth: true
      changeYear: true
      minDate: 1
      dateFormat: "mm/dd/yy"
      showOtherMonths: true
      selectOtherMonths: true
    
  initControlls: =>
    project = PiroPopup.pivotalProjects.get(@$('.add_story_project_id').val())
    # chosen
    @$('.chzn-select').chosen()
    # story points
    points = []
    points.push "<option value='-1'>Unestimated</option>"
    points.push "<option value='#{point}'>#{point} points</option>" for point in project.get('point_scale').split(",")
    @$('.add_story_point').html(points.join("")).trigger("liszt:updated")
    # memberships
    memberships = project.sortedMemberships()
    members = []
    for member in memberships when member? && member.person?
      members.push "<option value='#{member.person.id}' data-name='#{member.person.name}'>#{member.person.name} (#{member.person.initials})</option>"
    @$('.add_story_requester_id').html(members.join("")).val(PiroPopup.pivotalCurrentAccount.get('id')).trigger("liszt:updated")
    members.unshift("<option data-name=''></option>")
    @$('.add_story_owner_id').html(members.join("")).chosen(
      allow_single_deselect: true
    ).trigger("liszt:updated")
    # autocomplete
    projectLabels = if project.get('labels')? then project.get('labels').split(",") else []
    projectLabels = _.compact(projectLabels)
    if projectLabels.length > 0
      @$('input.add_story_labels').bind "keydown", (e) =>
        e.preventDefault() if e.keyCode is $.ui.keyCode.TAB && @$('input.add_story_labels').data("autocomplete") && @$('input.add_story_labels').data("autocomplete").menu.active
      .autocomplete
        minLength: 0
        source: (request, response) =>
          terms = request.term.split( /,\s*/ )
          term = terms.pop()
          filteredLabels = []
          for label in projectLabels
            filteredLabels.push(label) if _.indexOf(terms, label) is -1
          response($.ui.autocomplete.filter(filteredLabels, term))
        focus: =>
          false
        select: (event, ui) =>
          terms = $(event.currentTarget).val().split( /,\s*/ )
          terms.pop()
          terms.push(ui.item.value)
          terms.push("")
          $(event.currentTarget).val(terms.join(", "))
          false
    else
      @$('input.add_story_labels').autocomplete("destroy")
      
  initStoryType: =>
    switch @$('.add_story_story_type').val().toLowerCase()
      when "feature"
        @$('.add_story_release_date_box').hide()
        @$('.add_story_point_box').show()
      when "release"
        @$('.add_story_point_box').hide()
        @$('.add_story_release_date_box').show()
      else
        @$('.add_story_release_date_box').hide()
        @$('.add_story_point_box').hide()

  selectOwnedByMe: (e) =>
    e.preventDefault()
    @$('.add_story_owner_id').val(PiroPopup.pivotalCurrentAccount.get('id')).trigger("liszt:updated")
    
  submitStory: (e) =>
    e.preventDefault()
    storyType = @$('.add_story_story_type').val()
    attributes =
      story_type: storyType
      name: @$('.add_story_name').val()
      description: @$('.add_story_description').val()
      requested_by: @$('.add_story_requester_id').find(":selected").data('name')
      labels: $.trim(@$('.add_story_labels').val()).replace(/,$/i, "")
    switch storyType
      when "feature"
        _.extend(attributes, {estimate: @$('.add_story_point').val()})
      when "release"
        _.extend(attributes, {deadline: @$('.add_story_release_date').val()}) if @$('.add_story_release_date').val().length > 0
    # values
    _.extend(attributes, {owned_by: @$('.add_story_owner_id').find(":selected").data('name')}) if @$('.add_story_owner_id').find(":selected").data('name').length > 0
    # create story
    chrome.runtime.getBackgroundPage (bgPage) =>
      PiroPopup.bgPage = bgPage
      @$('.error_box').empty()
      PiroPopup.bgPage.PiroBackground.createAndSyncStory(
        PiroPopup.pivotalCurrentAccount.toJSON(), 
        @$('.add_story_project_id').val(), 
        {story: attributes}, 
        beforeSend: =>
          @$('.story_submit_controls').addClass('loading')
        success: (story) =>
          PiroPopup.db.setLatestProjectIdLS(story.project_id)
          Backbone.history.navigate("story/#{story.id}", {trigger: true, replace: true})
        error: =>
          @$('.story_submit_controls').removeClass('loading')
          @$('.error_box').text("Error to create story :(")
      )

  setStoryTmpTitle: =>
    storyTitle = PiroPopup.db.getStoryTitleTmpLS()
    @$('input.add_story_name').val(storyTitle) if storyTitle?
    
  onDestroyView: =>
    # on destroy