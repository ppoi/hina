requirejs.config({
  baseUrl: 'js/hina',
  paths: {
    'jquery': '../lib/jquery-1.9.1.min',
    'jquery.mobile': '../lib/jquery.mobile-1.3.1.min'
  },
  shim: {
    'jquery.mobile': {
      deps: ['jquery', 'transition']
    }
  }
});
require(['jquery', 'transition', 'jquery.mobile']);
