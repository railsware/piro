$ ->
  $("a.download-button").mouseover ->
    $(".rocket").addClass('active')

  $("a.download-button").mouseout ->
    $(".rocket").removeClass('active')
