module Rawbotz
  class OrderCreator
    include RawgentoModels

    attr_accessor :order, :supplier, :stock_products, :stock_products_hash

    def initialize(supplier)
      @supplier = supplier
    end

    # Returns [errors, order, stock_products(hash)]
    def process!
      # currently only for remote order
      @order = Order.create(state: :new, supplier: @supplier)
      @order.order_method = @supplier.order_method
      @stock_products = Models::StockProductFactory.create @supplier

      @stock_products.each do |stock_product|
        @order.order_items.create(local_product: stock_product.product,
                                  current_stock: stock_product.current_stock)
      end
      @stock_products_hash = @stock_products.map{|s| [s.product.id, s]}.to_h
      @order.save
    end
  end
end
