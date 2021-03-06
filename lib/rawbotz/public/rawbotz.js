$(document).ready(function() {
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

  // For Non-Remote Order Forms: add a pack
  $("a.plus-pack").click(function(e) {
    e.preventDefault();

    input_id = $(this).data("reference_input_id");
    inputField = $('#' + input_id);

    current = parseInt(inputField.val());
    if (isNaN(current)) {
      current = 0;
    }
    packsize = parseInt($(this).data("packsize"));
    if (isNaN(packsize)) {
      packsize = 0;
    }
    inputField.val(current + packsize);
    return false;
  });

  // For Non-Remote Order Forms: subtract a pack
  $("a.minus-pack").click(function(e) {
    e.preventDefault();

    input_id = $(this).data("reference_input_id");
    inputField = $("#" + input_id);
    current = parseInt(inputField.val());
    if (isNaN(current)) {
      current = 0;
    }
    packsize = parseInt($(this).data("packsize"));
    if (isNaN(packsize)) {
      packsize = 0;
    }
    if (current - packsize < 0) {
      inputField.val(0);
    } else {
      inputField.val(current - packsize);
    }
    return false;
  });

  // For Non-Remote Order Forms: empty field
  $("button.order-none").click(function(e) {
    e.preventDefault();
    inputField = $(this).siblings("input");
    inputField.val(0);
    return false;
  });

  // Stock / sales popup
  $('a.stock_show_action').on('click', function (e) {
    e.preventDefault();
    var url = $(e.target).data('url');
    var product_name = $(e.target).data('product');
    $('#modal-plot').dialog({
      resizable: false,
      autoOpen: false,
      height: 580,
      width: 950,
      show: 'fold',
      title: 'Stock and sales values of ' + product_name,
      modal: true
    });
    // move up and autoopen
    $('#modal-plot').load(url);
    $('#modal-plot').dialog("open");
  });

  // Fill order item input with last value
  $("button.reorder").click(function(e) {
    e.preventDefault();
    var order_item_id = $(e.target).data('order_item_id');
    var num_wished = $(e.target).data('num_wished');
    $("#item_" + order_item_id).val(num_wished);
  });
});

