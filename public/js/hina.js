requirejs.config({
  baseUrl: 'js/hina',
  paths: {
    'jquery': '../lib/jquery-1.9.1.min',
    'jquery.mobile': '../lib/jquery.mobile-1.3.1.min'
  },
  shim: {
    'jquery.mobile': {
      deps: ['jquery', 'boot']
    },
   'transition': {
      deps: ['jquery']
    }
  }
});

define('boot', ['require', 'jquery', 'transition'], function(require, $) {
  var setup_deferred = $.Deferred(),
      setup_promise = setup_deferred.promise();
  require(['threadsearch'], function() {
    alert('initialized!');
    setup_deferred.resolve();
  });
  $(document).on("mobileinit", function() {
    $('#welcome').on('pageshow', function() {
      setup_promise.done(function() {
        $.mobile.changePage('#threadsearch');
      });
    });

    $('div#thread').on('pagebeforeshow', handle_thread_pagebeforeshow)
        .on('pageshow', handle_thread_pageshow);
    $('div#thread-pointer form').on('submit', handle_threadPointer_submit);
    $('div#thread-pointer').on('popupafterclose', handle_threadPointer_afterclose);
    $('form#registerForm').on('submit', handle_registerForm_submit);
  });
});
require(['jquery.mobile']);
