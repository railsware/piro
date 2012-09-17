class PiroPopup.Views.StoriesForm extends Backbone.View
  tagName: "div"
  template: SHT['stories/form']
  events:
    "change .add_story_project_id"      : "changeProject"
    "change .add_story_story_type"      : "changeStoryType"
    "submit .add_story_form"            : "submitStory"
  
  initialize: =>

  render: =>
    $(@el).html(@template.render(
      projects: PiroPopup.pivotalProjects.toJSON()
    ))
    @initControlls()
    @initStoryType()
    @initCalendar()
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
    memberships = project.get('memberships')
    memberships = [] unless memberships?
    memberships = memberships.sort (a, b) =>
      if a.person? && a.person.name? &&
      b.person? && b.person.name?
        return -1 if (a.person.name < b.person.name)
        return 1 if (a.person.name > b.person.name)
      return 0
    members = []
    for member in memberships when member? && member.person?
      members.push "<option value='#{member.person.id}' data-name='#{member.person.name}'>#{member.person.name} (#{member.person.initials})</option>"
    @$('.add_story_requester_id').html(members.join("")).trigger("liszt:updated")
    members.unshift("<option></option>")
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
    
  submitStory: (e) =>
    e.preventDefault()
    
  onDestroyView: =>
    # destroy