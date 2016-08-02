module Rawbotz
  module Helpers
    module OrderItemColorHelper
      def order_item_class order_item
        if order_item.ordered? && order_item.all_ordered?
          "perfect_order"
        elsif order_item.out_of_stock?
          "out_of_stock"
        elsif order_item.not_ordered?
          "not_ordered"
        else
          "partly_available"
        end
      end
    end
  end
end
