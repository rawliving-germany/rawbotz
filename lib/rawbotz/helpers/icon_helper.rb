module Rawbotz
  module Helpers
    module IconHelper
      def add_icon tooltip_text: nil
        icon "plus", tooltip_text: tooltip_text
      end
      def error_icon tooltip_text: nil
        icon "flash", tooltip_text: tooltip_text
      end
      def index_icon tooltip_text: nil
        icon "th-list", tooltip_text: tooltip_text
      end
      def info_icon tooltip_text: nil
        icon "info-circle", tooltip_text: tooltip_text
      end
      def link_icon tooltip_text: nil
        icon "info-link", tooltip_text: tooltip_text
      end
      def order_icon tooltip_text: nil
        icon "shopping-cart", tooltip_text: tooltip_text
      end
      def packlist_icon tooltip_text: nil
        icon "paperclip", tooltip_text: tooltip_text
      end
      def packsize_icon tooltip_text: nil
        icon "cube", tooltip_text: tooltip_text
      end
      def product_icon tooltip_text: nil
        icon "cube", tooltip_text: tooltip_text
      end
      def products_icon tooltip_text: nil
        icon "cubes", tooltip_text: tooltip_text
      end
      def remote_icon tooltip_text: nil
        icon "globe", tooltip_text: tooltip_text
      end
      def sales_icon tooltip_text: nil
        icon "shopping-cart", tooltip_text: tooltip_text
      end
      def save_icon tooltip_text: nil
        icon "envelope", tooltip_text: tooltip_text
      end
      def settings_icon tooltip_text: nil
        icon "wrench", tooltip_text: tooltip_text
      end
      def shelve_icon tooltip_text: nil
        icon "map-signs", tooltip_text: tooltip_text
      end
      def stock_empty_icon tooltip_text: nil
        icon "battery-0", tooltip_text: tooltip_text
      end
      def stock_icon tooltip_text: nil
        icon "battery-2", tooltip_text: tooltip_text
      end
      def stock_full_icon tooltip_text: nil
        icon "battery-4", tooltip_text: tooltip_text
      end
      def success_icon tooltip_text: nil
        icon "smile-o", tooltip_text: tooltip_text
      end
      def supplier_icon tooltip_text: nil
        icon "truck", tooltip_text: tooltip_text
      end
      def view_icon tooltip_text: nil
        icon "eye", tooltip_text: tooltip_text
      end
      def warning_icon tooltip_text: nil
        icon "warning", tooltip_text: tooltip_text
      end

      def order_state_icon order
        case order.state
        when 'new'
          icon "star"
        when 'mailed'
          icon "envelope-o"
        when 'ordered'
          icon "arrow-right"
        when 'deleted'
          icon "remove"
        else
          icon "question"
        end
      end

      private
      def icon fa_name, tooltip_text: nil
        "<i class=\"fa fa-#{fa_name}\"%s></i>" % tooltip(tooltip_text)
      end
      def tooltip tooltip_text
        if tooltip_text
          " title=\"#{tooltip_text}\""
        end
      end
    end
  end
  # briefcase clone gift shopping-bag truck
end
