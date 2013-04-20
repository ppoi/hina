define(['jquery', 'controller'], function($, controller) {

var RegisterPage = controller.extend_page();
RegisterPage.prototype.setup_handlers = function(page) {
  $('#register-form').on('submit', function(event) {
    var source_url = $('#register-sourceUrl');
    if(source_url.val()) {
      $.mobile.loading('show', {text:'Loading', textVisible:true});
      $.ajax('thread', {
        type: 'PUT',
        data: {source_url:source_url.val()},
        dataType: 'json',
        processData: true,
        contentType: 'application/x-www-form-urlencoded; charset=UTF-8'
      }).done(function(data, textStatus, jqXHR) {
        window.alert('登録完了');
        source_url.val('');
        $.mobile.loading('hide');
      }).fail(function(jqXHR, textStatus, errorThrown) {
        window.alert(errorThrown);
        $.mobile.loading('hide');
      });
    }
    return false;
  });
};

controller.register(/^(register)$/, RegisterPage);
});
