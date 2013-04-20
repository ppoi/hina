define(['jquery', 'jquery.mobile'], function($) {

function Page(id) {
  this.id = id;
  this.hash = '#' + id;
  this.template_id = id;
};
Page.prototype.ensure_page = function() {
  var deferred = $.Deferred(),
      template;

  if(this.page) {
    return deferred.resolve(this.page).promise();
  }

  template = $('<div/>');
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
  this.ensure_page().done($.proxy(function(page) {
    if(!options.dataUrl) {
      options.dataUrl = this.hash;
    }
    $.mobile.changePage(page, options);
  }, this)).fail(function(textStatus, jqXHR) {
    alert('Fail to load page: ' + textStatus);
  });
};
Page.prototype.remove = function() {
  this.finalize();
  this.page.remove();
  this.page = null;
};
Page.prototype.finalize = $.noop;


///////////////////////////////////////////////////////////
// ページキャッシュ
/**
 * ページキャッシュのインスタンスを作成します。
 * @param capacity キャッシュのキャパシティ(最大ページ数)
 */
function PageCache(capacity) {
  this.capacity = capacity;
  this.cache = [];
};
/**
 * キャッシュにページを追加します。
 * @param page 追加するPageオブジェクト
 */
PageCache.prototype.add = function(page) {
  if(this.cache.length >= this.capacity) {
    //一番アクセスタイムスタンプが古いページ(キャッシュリストの最後尾)を削除
    this.cache.pop().remove();
  }
  //キャッシュリストの先頭に追加
  page.timestamp = new Date().getTime();
  this.cache.unshift(page);
  return page;
};
/**
 * キャッシュからidで識別されるページを取得します。
 * @param id Page ID
 * @returns idで識別されるキャッシュされたPageオブジェクト。存在しない場合 null
 */
PageCache.prototype.get = function(id) {
  for(var i = 0; i < this.cache.length; ++i) {
    var page = this.cache[i];
    if(page.id == id) {
      //ページのアクセスタイムスタンプを更新し、キャッシュリストをタイムスタンプの逆順でソート
      page.timestamp = new Date().getTime();
      this.cache.sort(function(a, b) {
        return b.timestamp - a.timestamp;
      });
      return page;
    }
  }
  return null;
};


function extend_page(subclass, superclass) {
  superclass = superclass || Page;
  subclass = subclass || function(){this.__super__.constructor.apply(this, arguments);};
  subclass.prototype = Object.create(superclass.prototype, {});
  subclass.prototype.__super__ = superclass.prototype;
  subclass.prototype.__super__.constructor = superclass;
  subclass.prototype.constructor = subclass;
  return subclass;
};

function Controller() {
  this.path_list = [];
  this.pages = {};
  this.page_cache = new PageCache(5);
  this.initial_page = 'threadsearch';
};
Controller.prototype.start = function() {
  $(document).on('pagebeforechange', $.proxy(function(event, data) {
    var to_page = data.toPage,
        options = data.options,
        hash, page,
        i, len, path, match;

    if(typeof to_page != 'string') {
      return;
    }

    hash = $.mobile.path.parseUrl(to_page).hash.substring(1);
    if(!hash) {
      hash = this.initial_page;
      options.changeHash = false;
    }

    for(i = 0, len = this.path_list.length; i < len; ++i) {
      path = this.path_list[i];
      match = path.exec(hash);
      if(match) {
        match.shift();
        page = this.page_cache.get(match[0]) || this.page_cache.add(this.create_page(path, match));
        page.transition(options);
        event.preventDefault();
        break;
      }
    }
  }, this));
};
Controller.prototype.create_page = function(path, args) {
  var page_class = this.pages[path]
      page = Object.create(page_class.prototype);
  page_class.apply(page, args);
  return page;
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
