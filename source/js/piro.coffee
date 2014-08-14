$ ->
  $("a.download-button").mouseover ->
    $(".rocket").css
      "-webkit-transform": "rotate(-45deg)"

  $("a.download-button").mouseout ->
    $(".rocket").css
      "-webkit-transform": "rotate(0deg)"