
module Rawbotz
  class OrderProcessor
    def initialize(order, logger=Logger.new("/dev/null"))
      @order = order
      @logger = logger
    end

    # Yield items, if block given
    def process!
      mech = Rawbotz::new_mech
      mech.login

      @order.order_items.processible.find_each do |item|
        if item.remote_product_id.present? && item.num_wished.present?
          log_product_handling item

          ordered_qty = mech.add_to_cart! item.remote_product_id, item.num_wished

          item.update(num_ordered: ordered_qty.to_i)

          log_result item

          yield item if block_given?
        else
          @logger.warn("Cannot order this item (no rem. prod/num_wished)")
          @logger.warn(item.attributes)
        end
      end
    end

    private

    def log_product_handling item
      @logger.info ("Will put in cart: #{item.remote_product_id}: #{item.num_wished}")
      @logger.debug ("  Local  Product: #{item.local_product.name}")
      @logger.debug ("  Remote Product: #{item.local_product.remote_product.name}")
    end

    def log_result item
      if item.out_of_stock?
        @logger.info "Product out of stock"
      elsif !item.all_ordered?
        @logger.info "Only #{item.num_ordered} (of #{item.num_wished}) could be ordered."
      else
        @logger.info "Ordered #{item.num_ordered} (of #{item.num_wished})."
      end
    end

  end
end
