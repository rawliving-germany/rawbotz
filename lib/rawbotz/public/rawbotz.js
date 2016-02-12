$(document).ready(function() {
  // Order View
  $(".order_none").click(function(e) {
    e.preventDefault();
    $(this).parent().children("input").val(0);
    $(this).parent().children("button").removeClass("pure-button-primary");
    $(this).addClass("pure-button-primary");
  });
  $(".add_pack").click(function(e) {
    e.preventDefault();
    $(this).parent().children("input").val($(this).data("num"));
    $(this).parent().children("button").removeClass("pure-button-primary");
    $(this).addClass("pure-button-primary");
  });

  // Remote Product Search with single input on page
  $("input#search-remote").autocomplete({
    source: function(request, response) {
      $.ajax({
        type: "POST",
        url: "/remote_products/search",
        data: "term=" + $("input#search-remote").val(),
        success: function(data) {
          var parsed = JSON.parse(data);
          response(parsed);
        }
      });
    },
    minLength: 1,
    select: function(event, ui) {
      $("input#remote_product_id").val(ui.item.product_id);
      $("input#search-remote").val(ui.item.name);
      $("input#search-remote").text(ui.item.name);
      $("#message").text(ui.item.name + " " + ui.item.product_id);
      return false;
    },
    open: function() {
      $(this).removeClass("ui-corner-all").addClass("ui-corner-top");
    },
    close: function() {
      $(this).removeClass("ui-corner-top").addClass("ui-corner-all");
    }
  }).autocomplete("instance")._renderItem = function(ul, item) {
      return $("<li>").append(item.name).appendTo(ul);
  };
});

