class PiroPopup.Views.StoriesForm extends Backbone.View
  tagName: "div"
  template: SHT['stories/form']
  events:
    "change .add_story_project_id"      : "changeProject"
    "submit .add_story_form"            : "submitStory"
  
  initialize: =>

  render: =>
    $(@el).html(@template.render(
      projects: PiroPopup.pivotalProjects.toJSON()
    ))
    @initSelects()
    this
  
  changeProject: (e) =>
    @initSelects()
    
  initSelects: =>
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
    
  submitStory: (e) =>
    e.preventDefault()
    
  onDestroyView: =>
    # destroy