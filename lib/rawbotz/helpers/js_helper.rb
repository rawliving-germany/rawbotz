module Rawbotz
  module Helpers
    module JSHelper
      # Initialize jquery UI tabs on #tab div.
      # in haml, use like this:
      # :javascript
      #   #{jqui_tab_init}
      def jqui_tab_init
        # ruby 2.3 unindented squiggly heredoc praise
        <<~JS_CODE
        $(function() {
          $( "#tabs" ).tabs({
            beforeLoad: function( event, ui ) {
              ui.jqXHR.fail(function() {
                ui.panel.html("Couldn't load this tab, there was an error.");
              });
            },
            activate: function(event, ui) { window.location.hash = ui.newPanel.attr('id'); }
           });
        });
        JS_CODE
      end
    end
  end
end
