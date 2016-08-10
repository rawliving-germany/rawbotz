module Rawbotz
  class OrderLinker
    include RawgentoModels

    OrderItemLine = Struct.new(:remote_product_name,
                               :qty_ordered,
                               :qty_refunded)
    OrderItemRecord = Struct.new(:order_item,
                                 :qty_ordered,
                                 :qty_refunded)

    attr_accessor :order, :orphans, :refunds

    def initialize(order)
      @order = order
    end

    # Links a local rawbotz order to a remote (magento) order.
    #
    # Set @orphans (remote order items that do not directly match,
    # @refunds (maps not only refunded order_item to OrderItemLine)
    # and @matched_order_items
    def link!
      # My, thats a hairy regex
      shop_order_id = @order.remote_order_link[/\d+/]
      @remote_order_lines = Rawbotz.mech.products_from_order(shop_order_id).map do |line|
        OrderItemLine.new(line[0],
                          line[2],
                          line[3])
      end
      matches, orphans = @remote_order_lines.partition{|line| !order_item(line).nil?}
      @matched_order_items = matches.map{|line| order_item line}
      @orphans = orphans
      @refunds = @matched_order_items.map do |oi|
        [oi, @remote_order_lines.find{|l| l.remote_product_name == oi.local_product.remote_product.name}]
      end.to_h
    end

    private
    # Get the order item of the order, or nil.
    def order_item order_item_line
      remote_product = RemoteProduct.find_by name: order_item_line.remote_product_name
      return nil if remote_product.blank?
      return nil if remote_product.local_product.blank?

      @order.order_items.processible.where(local_product: remote_product.local_product).first
    end
  end
end

