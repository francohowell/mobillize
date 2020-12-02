window.onload = function () {
  var upLink = document.querySelectorAll(".up");
  for (var i = 0; i < upLink.length; i++) {
    upLink[i].addEventListener('click', function () {
      var wrapper = this.parentElement.parentElement.parentElement.parentElement;

      if (wrapper.previousElementSibling)
        wrapper.parentNode.insertBefore(wrapper, wrapper.previousElementSibling);
    });
  }

  var downLink = document.querySelectorAll(".down");
  for (var i = 0; i < downLink.length; i++) {
    downLink[i].addEventListener('click', function () {
      var wrapper = this.parentElement.parentElement.parentElement.parentElement;

      if (wrapper.nextElementSibling)
        wrapper.parentNode.insertBefore(wrapper.nextElementSibling, wrapper);
    });
  }
}