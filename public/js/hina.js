requirejs.config({
  baseUrl: 'js/hina',
  paths: {
    'jquery': '../lib/jquery-1.9.1.min',
    'jquery.mobile': '../lib/jquery.mobile-1.3.1.min'
  },
  shim: {
    'jquery.mobile': {
      deps: ['jquery', 'hina']
    }
  }
});

define('hina', ['require', 'jquery'], function(require, $) {
  var setup_deferred = $.Deferred(),
      setup_promise = setup_deferred.promise();
  require(['threadsearch', 'thread', 'register', 'settings'], function() {
    setup_deferred.resolve();
  });
  $(document).on("mobileinit", function() {
    $('#welcome').on('pageshow', function() {
      setup_promise.done(function() {
        $.mobile.changePage(location.href);
      });
    }).on('pagehide', function(event, data) {
      $.mobile.firstPage = data.nextPage;
    });
  });
});
require(['jquery.mobile']);
