// Source for remote product search by name
function acSource(request, response) {
  $.ajax({
    type: "POST",
    url: "/remote_products/search",
    data: "term=" + request.term,
    success: function(data) {
      var parsed = JSON.parse(data);
      response(parsed);
    }
  });
}

// All search-remote-ajax inputs should autocomplete from remote product search
function installAutocompletion(jQuery) {
  $("input.search-remote-ajax").each( function() {
    field = $(this);
    field.autocomplete({
      source: acSource,
      minLength: 2,
      open: function() {
        $(this).removeClass("ui-corner-all").addClass("ui-corner-top");
      },
      close: function() {
        $(this).removeClass("ui-corner-top").addClass("ui-corner-all");
      },
      select: function(event, ui) {
        $(this).val(ui.item.name);
        $(this).parent().children("input.remote_product_id").val(ui.item.product_id);
        return false;
      },
    }).autocomplete("instance")._renderItem = function(ul, item) {
     return $("<li>").append(item.name).appendTo(ul);
    };
  });
}

// Links in link widget should link
function installAjaxLinkAction(jQuery) {
  $(".ajax_product_link").click(function(e){
    local_product_id = $(this).parent().parent().parent().children("input.local_product_id").val();
    input = $(this).parent().children("input.remote_product_id");

    remote_product_id = input.val();
    $.ajax({
      type: "POST",
      url: "/product/" + local_product_id + "/link",
      data: "remote_product_id=" + remote_product_id,
      success: function(data) {
        input.parent().parent().html(data);
      },
      error: function(data) {
        console.log(data);
        input.parent().parent().html("!" + data);
      }
    });

    e.preventDefault();
    return false;
  });
}

$(document).ready(installAutocompletion);
$(document).ready(installAjaxLinkAction);
