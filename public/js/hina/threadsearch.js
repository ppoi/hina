define(['jquery', 'controller'], function($, controller) {

var ThreadSearchPage = controller.extend_page(function(page_id) {
  this.__super__.constructor.apply(this, arguments);
  this.threadlist_initialized = false;
});
ThreadSearchPage.prototype.setup_handlers = function(page) {
  $('#threadsearch-form').on('submit', $.proxy(function(event) {
    $('#threadsearch-formbox').trigger('collapse');
    $.mobile.silentScroll();
    this.execute_threadsearch();
    return false;
  }, this));
  $('a[href="#search"]', page).on('click', $.proxy(function(event) {
    $('#threadsearch-formbox').trigger('expand');
    $.mobile.silentScroll();
    return false;
  }, this));
};
ThreadSearchPage.prototype.handle_pageshow = function(event ,data) {
  if(this.threadlist_initialized) {
    return;
  }
  this.execute_threadsearch();
};
ThreadSearchPage.prototype.execute_threadsearch = function() {
  var condition = {
    keyword:  $('#threadsearch-keyword').val(),
    archived: ($('#threadsearch-archived').val() == 'true'),
    sort: $('#threadsearch-sort input:checked').val(),
    sort_dir: $('#threadsearch-sort-dir').val()
  };

  $.mobile.loading('show', { text:'Loading', textVisible:true });
  $.ajax('thread', {
    type: 'GET',
    data: condition,
    dataType: 'json'
  }).done($.proxy(function(data, textStatus, jqXHR) {
    var threadlist = $('#threadlist');
    threadlist.html('<li data-role="list-divider">スレッド一覧<span class="ui-li-count">' + data.count + '/' + data.total + '</span></li>');
    for(var i = 0; i < data.threadlist.length; ++i) {
      var thread = data.threadlist[i];
      var item = $('<a/>', {href:'#thread:' + thread.key}).text(thread.title);
      if(thread.note) {
        item.append($('<p class="thread-note"/>').text(thread.note));
      }
      var post_count_class = thread.archived ? 'post-count post-archived' : 'post-count';
      item.append($('<p class="thread-info"/>').append(
        $('<span class="' + post_count_class + '"/>').text(String(thread.post_count)),
        $('<br/>'),
        $('<span class="thread-period"/>').append(
          $('<span class="thread-created-date"/>').text(thread.created_date),
          $('<span class="thread-lastpost-date"/>').text(thread.lastpost_date)
        ))
      );
      threadlist.append($('<li><span class="li-index">' + (i+1) + '</span> </li>').append(item));
    }
    threadlist.listview('refresh');
    $.mobile.loading('hide');
    this.threadlist_initialized = true;
  }, this)).fail(function(jqXHR, textStatus, errorThrown) {
    window.alert(errorThrown);
  });
};


controller.register(/^(threadsearch)$/, ThreadSearchPage);
});
