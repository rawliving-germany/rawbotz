module Rawbotz
  class OrderItemParams
    attr_accessor :params
    attr_accessor :order

    def initialize params, order
      @params = params
      @order  = order
    end

    # Yes, don't do that at home.
    def create_or_change_order_items
      @params.select{|p| p.start_with?("item_")}.each do |p, val|
        # why > 0 ?
        if val && val.to_i > 0
          qty = val.to_i
          oi = @order.order_items.where(local_product_id: p[5..-1]).first_or_create
          oi.update(num_wished: qty)
        end
      end
    end
  end
end
