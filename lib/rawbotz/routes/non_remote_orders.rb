require 'rawbotz/routes'
require 'date'

module Rawbotz::RawbotzApp::Routing::NonRemoteOrders
  include Rawbotz
  include RawgentoModels

  def self.registered(app)
    # app.get  '/orders/non_remote', &show_suppliers_orders
    show_suppliers_orders = lambda do
      @suppliers = Supplier.order(:name)
      haml "orders/non_remotes".to_sym
    end

    # app.get  '/order/non_remote/:supplier_id/new', &create_supplier_order
    create_supplier_order = lambda do
      @supplier = Supplier.find(params[:supplier_id])

      if @supplier.order_template.to_s == ""
        add_flash :warning, "You need to set the mailer template to order from this supplier"
        redirect "/supplier/#{@supplier.id}#tab_order_settings"
      end

      order_creator = Processors::OrderCreator.new(@supplier)
      order_creator.process!
      @order = order_creator.order
      @stock_products_hash = order_creator.stock_products_hash

      if order_creator.succeeded?
        add_flash :success, order_creator.messages
        redirect "/order/non_remote/#{@order.id}".to_sym
      else
        add_flash :error, order_creator.messages
        redirect "/supplier/#{@supplier.id}".to_sym
      end
    end

    # app.get  '/order/non_remote/:order_id', &show_supplier_order
    show_supplier_order = lambda do
      @order    = Order.find(params[:order_id])
      @supplier = @order.supplier
      if @supplier.order_template.to_s == ""
        add_flash :warning, "You need to set the mailer template to order from this supplier"
        redirect "/supplier/#{@supplier.id}#tab_order_settings"
      end

      begin
        stock_products = Models::StockProductFactory.create @supplier
        @stock_products_hash = stock_products.map{|s| [s.product.id, s]}.to_h

        @products = @order.order_items.map{|oi| oi.local_product}
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        @stock_products_hash = {}
        add_flash :error, "Cannot connect to MySQL database (#{e.message})"
      end

      @order_mail = Rawbotz::MailTemplate.create(@order)

      haml "order/non_remote".to_sym
    end

    # app.post '/order/non_remote/:order_id', &show_supplier_order_preview
    show_supplier_order_preview = lambda do
      @supplier = Supplier.find(params[:supplier_id])
      @products = @supplier.local_products
      @order    = Order.find(params[:order_id])

      # Certain orders should not be changed
      if @order.state != 'new'
        add_flash :error, "Orders in state #{@order.state} cannot be changed!"
        redirect "order/non_remote/#{@order.id}"
      end

      begin
        stock_products = Models::StockProductFactory.create @supplier
        @stock_products_hash = stock_products.map{|s| [s.product.id, s]}.to_h
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        @stock_products_hash = {}
        add_flash :error, "Cannot connect to MySQL database (#{e.message})"
      end

      order_item_params = OrderItemParams.new(params, @order)
      order_item_params.create_or_change_order_items

      @order.public_comment   = params[:public_comment]
      @order.internal_comment = params[:internal_comment]

      @order_mail = Rawbotz::MailTemplate.create(@order)
      @order.order_result = @order_mail.body

      @order.ordered_at = DateTime.now
      @order.save

      if params['action'] == 'fix'
        @order.order_items.find_each do |oi|
          stock = @stock_products_hash[oi.local_product.id]&.current_stock
          oi.update(num_ordered: oi.num_wished, current_stock: stock)
        end
        @order.update(state: :mailed)
        add_flash :success, "Order marked as mailed"
        redirect '/orders'
      elsif params['action'] == "delete"
        @order.update(state: :deleted)
        add_flash :success, 'Order marked deleted'
        redirect '/orders'
      else
        add_flash :success, "Order saved"
      end

      haml "order/non_remote".to_sym
    end

    # app.get  '/stockexplorer/:supplier_id', &show_stock_explorer
    show_stock_explorer = lambda do
      @supplier = Supplier.find(params[:supplier_id])
      begin
        @stock_products = Models::StockProductFactory.create Supplier.where(id: params[:supplier_id])
        @stock_products = @stock_products.map{|s| [s.product.product_id, s]}.to_h
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        @stock_products = {}
        add_flash :error, "Cannot connect to MySQL database (#{e.message})"
      end
      haml 'stockexplorer/stockexplorer'.to_sym, layout: request.xhr? ? "xhr_layout".to_sym : true
    end

    # routes
    app.get  '/orders/non_remote', &show_suppliers_orders
    app.get  '/order/non_remote/:order_id', &show_supplier_order
    app.post '/order/non_remote/:order_id', &show_supplier_order_preview
    app.get  '/order/non_remote/:supplier_id/new', &create_supplier_order
    app.get  '/stockexplorer/:supplier_id', &show_stock_explorer
  end
end
