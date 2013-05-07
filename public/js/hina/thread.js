define(['jquery', 'controller'], function($, controller) {

var ThreadPage = controller.extend_page();
ThreadPage.prototype.setup_handlers = function(page) {
  $('#thread-pointer-form', page).on('submit', $.proxy(function() {
    $('#thread-pointer', page)
      .one('popupafterclose', $.proxy(this.scroll_to_response, this))
      .popup('close');
    return false;
  }, this)); 
};
ThreadPage.prototype.handle_pagebeforeshow = function(event, dat) {
  $('#threadview').empty();
  document.title = 'ヒナ';
};
ThreadPage.prototype.handle_pageshow = function(event, dat) {
  var view = $('#threadview'),
      standalone = $('#setting-standalone').val() == 'true',
      log = $('#threadview-log'),
      lap1 = new Date();

  if(log.length == 0) {
    log = $('<div id="threadview-log">').appendTo(view);
  }

  $.mobile.loading('show', {text:'Loading', textVisible:true});
  $.ajax('thread/' + this.thread_id, {
    data: standalone ? {standalone:standalone} : null
  }).done($.proxy(function(data, textStatus, jqXHR) {
    var lap2 = new Date();
    var networkCost = lap2.getTime() - lap1.getTime();
    log.append($('<span class="threadview-log-network"/>').text(networkCost));
    var post_count_class = data.archived ? 'post-count post-archived' : 'post-count';
    view.append($('<div class="thread-header ui-body ui-body-d"/>').append(
      $('<h1 class="thread-title"/>').text(data.title),
      $('<div class="thread-info"/>').append(
        $('<a class="thread-source-url" href="' + data.source_url + '"/>').text(data.source_url),
        $('<br/>'),
        $('<span class="' + post_count_class + '"/>').text(String(data.post_count)),
        $('<br/>'),
        $('<span class="thread-period"/>').append(
          $('<span class="thread-created-date"/>').text(data.created_date),
          $('<span class="thread-lastpost-date"/>').text(data.lastpost_date)
        )
      )
    ));
    this.render_thread_posts(data.posts, view);
    var lap3 = new Date();
    var renderCost = lap3.getTime() - lap2.getTime();
    log.append($('<span class="threadview-log-render"/>').text(renderCost));
    document.title = data.title;
    $.mobile.silentScroll();
    $.mobile.loading('hide');
  }, this)).fail(function(jqXHR, textStatus, errorThrown) {
    window.alert(errorThrown);
  });
};
ThreadPage.prototype.render_thread_posts = function(posts, threadview) {
  for(var i = 0, len = posts.length; i < len; ++i) {
    var post = posts[i];
    threadview.append($('<div id="' + post.key + '" class="post"/>').append(
      $('<div class="post-header"/>').append(
        $('<span class="post-number"/>').text(String(i + 1)),
        $('<span class="post-author"/>').text(post.author),
        $('<span class="post-mail"/>').text(post.mail ? post.mail : ''),
        $('<br/>'),
        $('<span class="post-date"/>').text(post.post_date),
        $('<span class="post-hash"/>').text(post.author_hash)
      ),
      $('<div class="post-content"/>').html(post.contents)
    ));
  }
};
ThreadPage.prototype.scroll_to_response = function() {
  var resnum = $('#thread-pointer-resnumber').val(),
      response;
  if(!resnum) {
    $.mobile.silentScroll();
  }
  else {
    response = document.getElementById(this.thread_id + ':' + resnum);
    if(response) {
      $.mobile.silentScroll($(response).position().top - 56);
    }
  }
};
ThreadPage.prototype.transition = function(options) {
  var match = /^thread:(.+)/.exec(options.originalHash);
  this.thread_id = match[1];
  this.hash = options.originalHash;
  this.__super__.transition.apply(this, arguments);
};

controller.register(/^(thread):.+$/, ThreadPage);
});
