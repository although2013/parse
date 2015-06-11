$(document).ready(function () {


  function scroll_in (num) {
    var top = ($($('.a-class table thead')[num]).position()["top"] + $($('.a-class table thead')[num]).height())
    var end = $($('.a-class table thead')[num]).position()["top"] + $($('.a-class table')[num]).height()
    return ($(window).scrollTop() > top && $(window).scrollTop() < end)
  }

  function check_position () {
    if (scroll_in(0)) {
      $(".my-top-fix").remove()
      add_top_bar(0)
    } else if (scroll_in(1)) {
      $(".my-top-fix").remove()
      add_top_bar(1)
    } else {
      $(".my-top-fix").remove()
    }
  };

  function add_top_bar (num) {
    $("body").prepend('<div class="my-top-fix"><table class="table table-bordered"><thead></thead></table></div>')
    str = $($('.a-class table thead')[num]).html()
    $(".my-top-fix table thead").append(str)


    $($('.my-top-fix table thead th')[0]).addClass( "not-show-white" ).text("0000000000")
    $($('.my-top-fix table thead th')[1]).addClass( "not-show-white" ).text("王王王")

    var delt = $($('.a-class table thead')[num]).width() - $('.my-top-fix').width()
    var left = $($('.a-class table thead')[num]).position()["left"] - $(window).scrollLeft()
    $('.my-top-fix').css("left", (left+"px")).css("height", ($($('.a-class table thead')[num]).height()+'px'))

    $('.my-top-fix').css("position", "fixed").css("z-index", "500").css("top","0").css("background-color", "white").css("margin-bottom", "0px").css("padding-bottom", "0px")
  };


  setInterval(function() {
    check_position();
  }, 150);




});