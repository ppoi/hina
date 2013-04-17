
function handle_pagebeforechange(event, data) {

  if(typeof data.toPage != 'string') {
    return;
  }

  var url = $.mobile.path.parseUrl(data.toPage);
  if(url.hash.match('^#thread:')) {
    event.preventDefault();
    data.options.dataUrl = data.toPage;
    $.mobile.changePage($('#thread'), data.options);
  }
}

var threadlist_initialized = false;

function render_threadlist(condition) {
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
  }).done(function(data, textStatus, jqXHR) {
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
    threadlist_initialized = true;
  }).fail(function(jqXHR, textStatus, errorThrown) {
    window.alert(errorThrown);
  });

}

function handle_threadsearch_submit(event) {
  event.preventDefault();

  $('#threadsearch-form').trigger('collapse');
  $.mobile.silentScroll();
  render_threadlist();

  return false;
}

function handle_threadlist_pageshow(event, data) {
  if(threadlist_initialized) {
    return;
  }

  render_threadlist();
}

function handle_thread_pagebeforeshow(event, dat) {
  $('#threadview').empty();
  document.title = 'ヒナ';
}

function render_thread_posts(posts, threadview) {
  if(!threadview) {
    threadview = $('#threadview');
  }

  for(var i = 0, len = posts.length; i < len; ++i) {
    var post = posts[i];
    threadview.append($('<div id="' + post.key.replace(/:/g, '-') + '" class="post"/>').append(
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
}

function handle_thread_pageshow(event, dat) {
  var url = $.mobile.path.parseUrl(location.href),
      match = /#thread:([^&]+)/.exec(url.hash),
      thread_id = match[1],
      page = $(event.target),
      view = $('#threadview'),
      standalone = $('#setting-standalone').val() == 'true',
      log = $('#threadview-log');

  if(log.length == 0) {
    log = $('<div id="threadview-log">').appendTo(view);
  }

  $.mobile.loading('show', { text:'Loading', textVisible:true });
  var lap1 = new Date();
  $.ajax('thread/' + thread_id, {
    data: standalone ? { standalone: standalone } : null
  }).done(function(data, textStatus, jqXHR) {
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
    render_thread_posts(data.posts, view);
    var lap3 = new Date();
    var renderCost = lap3.getTime() - lap2.getTime();
    log.append($('<span class="threadview-log-render"/>').text(renderCost));
    document.title = data.title;
    $.mobile.silentScroll();
    $.mobile.loading('hide');
  }).fail(function(jqXHR, textStatus, errorThrown) {
    window.alert(errorThrown);
  });
}


var scroll_to_position = -1;
function handle_threadPointer_submit(event) {
  var pointerForm = $('#thread-pointer'),
      resnum = $('#thread-pointer-resnumber').val();

  if(!resnum) {
    scroll_to_position = null;
    pointerForm.popup('close');
    $.mobile.silentScroll();
  }
  else {
    var url = $.mobile.path.parseUrl(location.href),
        match = /#thread:([^&]+)/.exec(url.hash),
        res = $('#' + match[1].replace(/:/g, '-') + '-' + resnum);
    if(res.length) {
      scroll_to_position = res.position().top;
      pointerForm.popup('close');
    }
  }
  return false;
}
function handle_threadPointer_afterclose(event) {
   if(scroll_to_position !== -1) {
     if(scroll_to_position) {
       scroll_to_position -= 56;
     }
     $.mobile.silentScroll(scroll_to_position);
     scroll_to_position = -1;
   }
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
  $(document).on("pagebeforechange", handle_pagebeforechange);
  $('div#main').on("pageshow", handle_threadlist_pageshow);
  $('form#threadsearch').on('submit', handle_threadsearch_submit);
  $('div#thread').on('pagebeforeshow', handle_thread_pagebeforeshow)
      .on('pageshow', handle_thread_pageshow);
  $('div#thread-pointer form').on('submit', handle_threadPointer_submit);
  $('div#thread-pointer').on('popupafterclose', handle_threadPointer_afterclose);
  $('form#registerForm').on('submit', handle_registerForm_submit);
});


