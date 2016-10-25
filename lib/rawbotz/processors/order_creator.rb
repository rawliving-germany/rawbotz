module Rawbotz
  module Processors
    class OrderCreator < Processor
      include RawgentoModels

      attr_accessor :order, :supplier, :stock_products, :stock_products_hash

      def initialize(supplier)
        @success_message = "New Order created"
        @supplier = supplier
        super()
      end

      # Returns [errors, order, stock_products(hash)]
      def process!
        if @supplier.order_method.blank?
          STDERR.puts "Supplier without order_method found! Assume 'mail'"
        end

        @order = Order.create(state: :new, supplier: @supplier,
                              order_method: @supplier.order_method)

        begin
          create_order_items
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          @errors << e.message
          @order.update(state: "error: #{e.message}")
        end
        if !@order.save
          @errors << "Order could not be saved"
        end
      end

      private

      # Setup order items for an order with mail order method
      def create_order_items
        @stock_products = Models::StockProductFactory.create @supplier

        @stock_products.each do |stock_product|
          @order.order_items.create(local_product: stock_product.product,
                                    current_stock: stock_product.current_stock)
        end
        @stock_products_hash = @stock_products.map{|s| [s.product.id, s]}.to_h
      end
    end
  end
end
