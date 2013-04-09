
function handle_pagebeforechange(event, data) {
  if(data.options.dataUrl) {
    return;
  }

  var pageurl = location.href;
  if(typeof data.toPage == 'string') {
    pageurl = data.toPage;
  }
  data.options.dataUrl = $.mobile.path.parseUrl(pageurl);
  var pageId = data.options.dataUrl.hash;
  if(!pageId) {
    pageId = '#main';
  }
  else if(pageId.match('^#thread:')) {
    pageId = '#thread';
  }
  $.mobile.changePage($(pageId), data.options);
  event.preventDefault();
}

var threadlist_initialized = false;

function render_threadlist(condition) {
  $.mobile.loading('show', { text:'Loading', textVisible:true });
  $.ajax('thread', {
    type: 'GET',
    data: condition,
    dataType: 'json'
  }).done(function(data, textStatus, jqXHR) {
    var threadlist = $('#threadlist');
    threadlist.html('<li data-role="list-divider">スレッド一覧<span class="ui-count">' + data.threadlist.length + '</span></li>');
    for(var i = 0; i < data.threadlist.length; ++i) {
      var thread = data.threadlist[i];
      var item = $('<a/>', {href:'#thread:' + thread.key}).text(thread.title);
      if(thread.note) {
        item.append($('<p class="thread-note"/>').text(thread.note));
      }
      item.append($('<p class="thread-date"/>').text(thread.created_date + ' ' + thread.lastpost_date));
      threadlist.append($('<li><span class="li-index">' + (i+1) + '</span> </li>').append(item));
    }
    threadlist.listview('refresh');
    $.mobile.loading('hide');
    threadlist_initialized = true;
  }).fail(function(jqXHR, textStatus, errorThrown) {
    window.alert(errorThrown);
  });

}

function handle_threadsearch_submit(event) {
  event.preventDefault();

  var keyword = $('#threadsearch-keyword').val(),
      archived = ($('#threadsearch-archived').val() == 'true'),
      sort = $('#threadsearch-sort input:checked').val();

  $('#threadsearch-form').trigger('collapse');
  $.mobile.silentScroll();
  render_threadlist({
    keyword: keyword,
    archived: archived,
    sort: sort
  });

  return false;
}

function handle_threadlist_pageshow(event, data) {
  if(threadlist_initialized) {
    return;
  }

  render_threadlist();
}

function handle_thread_pagebeforeshow(event, dat) {
  $('div#threadview').text('にゃー');
}

function handle_thread_pageshow(event, dat) {
  var url = $.mobile.path.parseUrl(location.href)
  var thread_id = url.hash.substring(8);
  var page = $(event.target);
  $.mobile.loading('show', { text:'Loading', textVisible:true });
  $.ajax('thread/' + thread_id, {
  }).done(function(data, textStatus, jqXHR) {
    var view = $('#threadview');
    view.append($('<div class="thread-header"/>').append(
      $('<h1/>').text(data.title),
      $('<div class="thread-info"/>').append(
        $('<span class="post-count"/>').text(String(data.post_count)),
        $('<span class="thread-period"/>').append(
          $('<span class="thread-created-date"/>').text(data.created_date),
          $('<span class="thread-lastpost-date"/>').text(data.lastpost_date)
        )
      )
    ));
    for(var i = 0; i < data.posts.length; ++i) {
      var post = data.posts[i];
      view.append($('<div class="post"/>').append(
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
    $.mobile.loading('hide');
  }).fail(function(jqXHR, textStatus, errorThrown) {
    window.alert(errorThrown);
  });
}

function handle_registerForm_submit(event) {
  event.preventDefault();
  var sourceUrl = $('#register-sourceUrl');
  if(sourceUrl.val()) {
    $.mobile.loading('show', { text: 'Loading', textVisible: true });
    $.ajax('thread', {
      type: 'PUT',
      data: { source_url: sourceUrl.val() },
      dataType: 'json',
      processData: true,
      contentType: 'application/x-www-form-urlencoded; charset=UTF-8'
    }).done(function(data, textStatus, jqXHR) {
      window.alert('登録完了');
      sourceUrl.val('');
      $.mobile.loading('hide');
    }).fail(function(jqXHR, textStatus, errorThrown) {
      window.alert(errorThrown);
      $.mobile.loading('hide');
    });
  }
  return false;
}

$(document).on("mobileinit", function(){
  $(document).ready(function(event) {
    $(document).on("pagebeforechange", handle_pagebeforechange);
    $('div#main').on("pageshow", handle_threadlist_pageshow);
    $('form#threadsearch').on('submit', handle_threadsearch_submit);
    $('div#thread').on('pagebeforeshow', handle_thread_pagebeforeshow)
        .on('pageshow', handle_thread_pageshow);
    $('form#registerForm').on('submit', handle_registerForm_submit);
  });
});


