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
          if @order.order_method == "magento"
            create_order_items_magento
          else
            create_order_items_mail
          end
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

      # Setup order items for an order with magento order method
      def create_order_items_magento
        RawgentoDB::Query.understocked.each do |product_id, name, min_qty, stock|
          local_product = LocalProduct.find_by(product_id: product_id)
          if local_product.present? && local_product.supplier == @order.supplier
            @order.order_items.create(local_product: local_product,
                                      current_stock: stock,
                                      min_stock: min_qty)
           end
        end
      end

      # Setup order items for an order with mail order method
      def create_order_items_mail
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
