// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require jquery/jquery-3.1.1.min.js
//= require popper
//= require bootstrap
//= require pace/pace.min.js
//= require peity/jquery.peity.min.js
//= require slimscroll/jquery.slimscroll.min.js
//= require metisMenu/jquery.metisMenu.js
//= require inspinia.js
//= require sms_tools
//= require questions_up_down

$.jMaskGlobals = {
    watchDataMask: true
};

// $('[data-provider="summernote"]').each(function(){
//     $(this).summernote({ });
// })

 // Determine Page Storage
 function page_set_storage(page_name) {
    console.log(`Executing Page Set Storage On ${page_name}`);
    var page = localStorage.getItem("PageName");
    if (page) {
        if (page != page_name) {
            localStorage.clear();
            localStorage.setItem("PageName", page_name);
        }
    }else{
        localStorage.clear();
        localStorage.setItem("PageName", page_name);
    }
 };
