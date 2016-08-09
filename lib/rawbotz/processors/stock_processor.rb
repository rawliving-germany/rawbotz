module Rawbotz
  class StockProcessor
    include RawgentoModels

    attr_accessor :errors

    def initialize(order, params)
      @order  = order
      @params = params
      @errors = []
    end

    # Add items to stock, setting them available if they were not before (and
    # stock is positive.
    #
    # Returns and sets @error hash which is empty if everything went smooth.
    def process!
      @params.each do |param_name, param_value|
        if param_name.to_s.start_with?("qty_delivered_") && param_value != ""
          order! param_name[14..-1], param_value
        end
      end

      if @order.order_items.processible.where("num_stocked IS NULL").count == 0
        @order.update(state: 'stocked')
      else
        @errors << "Not all items stocked"
      end

      @errors
    end

    private

    def order! order_item_id, qty
      order_item = @order.order_items.find(order_item_id)
      # This should be logged
      return if order_item.blank? || order_item.stocked?

      begin
        #RawgentoDB::Query.update_stock order_item.local_product.product_id, qty.to_i
        #RawgentoDB::Query.set_available_on_stock order_item.local_product.product_id
        # Would be good to log that
        order_item.update(num_stocked: qty.to_i, state: :stocked)
        order_item.save
      rescue Exception => e
        @errors << e.message
      end
    end
  end
end