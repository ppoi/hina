define(['jquery', 'jquery.mobile'], function($) {

function Page(id) {
  this.id = id;
  this.template_id = id;
};
Page.prototype.ensure_page = function() {
  var template = $('<div/>'),
      deferred = $.Deferred();

  if(this.page) {
    return deferred.resolve(this.page).promise();
  }

  template.load('template/' + this.template_id + '.html', $.proxy(function(contents, textStatus, jqXHR) {
    if(textStatus == 'success' || textStatus == 'notmodified') {
      this.page = this.setup_page(template);
      deferred.resolve(this.page);
    }
    else {
      deferred.reject(textStatus, jqXHR);
    }
  },this));
  return deferred.promise();
};
Page.prototype.setup_page = function(template) {
  var page = this.process_template(template);
  $.mobile.pageContainer.append(page);
  this.setup_pageevent_handlers(page);
  this.setup_handlers(page);
  page.page();
  return page;
};
Page.prototype.process_template = function(template) {
  return $('div:first', template);
};
Page.prototype.setup_pageevent_handlers = function(page) {
  page.on('pagebeforecreate', $.proxy(this.handle_pagebeforecreate, this))
    .on('pagecreate', $.proxy(this.handle_pagecreate, this))
    .on('pagebeforeshow', $.proxy(this.handle_pagebeforeshow, this))
    .on('pageshow', $.proxy(this.handle_pageshow, this))
    .on('pagebeforehide', $.proxy(this.handle_pagebeforehide, this))
    .on('pagehide', $.proxy(this.handle_pagehide, this));
};
Page.prototype.setup_handlers = $.noop;
Page.prototype.handle_pagebeforecreate = $.noop;
Page.prototype.handle_pagecreate = $.noop;
Page.prototype.handle_pagebeforeshow = $.noop;
Page.prototype.handle_pageshow = $.noop;
Page.prototype.handle_pagebeforehide = $.noop;
Page.prototype.handle_pagehide = $.noop;
Page.prototype.transition = function(options) {
  this.ensure_page().done(function(page) {
    $.mobile.changePage(page, options);
  }).fail(function(textStatus, jqXHR) {
    alert('Fail to load page: ' + textStatus);
  });
};


function extend_page(subclass, superclass) {
  superclass = superclass || Page;
  subclass.prototype = Object.create(superclass.prototype, {});
  subclass.prototype.__super__ = superclass.prototype;
  subclass.prototype.__super__.constructor = superclass;
  subclass.prototype.constructor = subclass;
  return subclass;
};

function Controller() {
  this.path_list = [];
  this.pages = {};
};
Controller.prototype.start = function() {
  $(document).on('pagebeforechange', $.proxy(function(event, data) {
    var to_page = data.toPage,
        options = data.options,
        page_id, page,
        i, len, path, match;

    if(typeof to_page != 'string') {
      return;
    }

    page_id = $.mobile.path.parseUrl(to_page).hash.substring(1);

    for(i = 0, len = this.path_list.length; i < len; ++i) {
      path = this.path_list[i];
      match = path.exec(page_id);
      if(match) {
        match.shift();
        page = new this.pages[path](page_id, match);
        page.transition(options);
        event.preventDefault();
        break;
      }
    }
  }, this));
};
Controller.prototype.register = function(path, page_class) {
  this.path_list.push(path);
  this.pages[path] = page_class;
};

var controller = new Controller();
controller.start();

return {
  Page: Page,
  extend_page: extend_page,
  register: $.proxy(controller.register, controller)
};


});
