require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::NonRemoteOrders
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
      else
        @order    = Order.create(state: :new, supplier: @supplier)
        @products = LocalProduct.supplied_by(@supplier)
        @stock    = {}
        begin
          @monthly_sales = Rawbotz::SalesData.sales_since(Date.today - 31 * 4, @products)
          RawgentoDB::Query.stock.each {|s| @stock[s.product_id] = s.qty}
        rescue Exception => e
          @monthly_sales = {}
          add_flash :error, "Cannot connect to MySQL database (#{e.message})"
        end

        # Get the current stock value
        @products.find_each do |product|
          @order.order_items.create(local_product: product,
                                    current_stock: @stock[product.product_id],
                                    min_stock:     nil)
        end

        @order.save
        add_flash :success, "New Order created"

        redirect "/order/non_remote/#{@order.id}".to_sym
      end
    end

    # app.get  '/order/non_remote/:order_id', &show_supplier_order
    show_supplier_order = lambda do
      @order    = Order.find(params[:order_id])
      @supplier = @order.supplier
      if @supplier.order_template.to_s == ""
        add_flash :warning, "You need to set the mailer template to order from this supplier"
        redirect "/supplier/#{@supplier.id}#tab_order_settings"
      else
        @stock    = {}
        begin
          @products = @order.order_items.map{|oi| oi.local_product}
          @monthly_sales = Rawbotz::SalesData.sales_since(Date.today - 31 * 4, @products)
          RawgentoDB::Query.stock.each {|s| @stock[s.product_id] = s.qty}
        rescue Exception => e
          @monthly_sales = {}
          add_flash :error, "Cannot connect to MySQL database (#{e.message})"
        end
        @mail_preview_subject = Rawbotz::MailTemplate.extract_subject(
          @supplier.order_template, @order)
        @mail_preview_text    = Rawbotz::MailTemplate.consume(
          @supplier.order_template, @order)
        @mailto_url           = Rawbotz::MailTemplate.create_mailto_url(
          @supplier, @order)
        haml "order/non_remote".to_sym
      end
    end

    # app.post '/order/non_remote/:order_id', &show_supplier_order_preview
    show_supplier_order_preview = lambda do
      @supplier = Supplier.find(params[:supplier_id])
      @products = @supplier.local_products
      @order    = Order.find(params[:order_id])
      @stock    = {}

      # Certain orders should not be changed
      if @order.state != 'new'
        add_flash :error, "Orders in state #{@order.state} cannot be changed!"
        redirect "order/non_remote/#{@order.id}"
      end

      begin
        @monthly_sales = Rawbotz::SalesData.sales_since(Date.today - 31 * 4, @products)
        RawgentoDB::Query.stock.each {|s| @stock[s.product_id] = s.qty}
      rescue Exception => e
        @monthly_sales = {}
        add_flash :error, "Cannot connect to MySQL database (#{e.message})"
      end

      params.select{|p| p.start_with?("item_")}.each do |p, val|
        # why > 0 ?
        if val && val.to_i > 0
          qty = val.to_i
          oi = @order.order_items.where(local_product_id: p[5..-1]).first_or_create
          oi.update(num_wished: qty)
        end
      end
      @order.public_comment   = params[:public_comment]
      @order.internal_comment = params[:internal_comment]

      @mail_preview_subject = Rawbotz::MailTemplate.extract_subject(
        @supplier.order_template, @order)
      @mail_preview_text    = Rawbotz::MailTemplate.consume(
        @supplier.order_template, @order)
      @mailto_url           = Rawbotz::MailTemplate.create_mailto_url(
        @supplier, @order)

      @order.order_result = @mail_preview_text
      @order.save
      if params['action'] == 'fix'
        @order.order_items.find_each do |oi|
          oi.num_ordered   = oi.num_wished
          oi.current_stock = @stock[oi.local_product.product_id]
          oi.save
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
        @stock    = {}
        #begin
          #@monthly_sales = Rawbotz::SalesData.sales_since(Date.today - 31 * 4, @products)
          RawgentoDB::Query.stock.each {|s| @stock[s.product_id] = s.qty}
        #rescue Exception => e
        #  @monthly_sales = {}
        #  add_flash :error, "Cannot connect to MySQL database (#{e.message})"
        #end

      #-> db query num_sales_since
      days_ago_30  = Date.today - 30
      days_ago_60  = Date.today - 60
      days_ago_90  = Date.today - 90
      days_ago_356 = Date.today - 356

      # TODO 30 90 356
      product_ids = @supplier.local_products.map &:product_id
      @sales_30 = RawgentoDB::Query.num_sales_since(days_ago_30, product_ids)
      @sales_60 = RawgentoDB::Query.num_sales_since(days_ago_60, product_ids)
      @sales_90 = RawgentoDB::Query.num_sales_since(days_ago_90, product_ids)
      @sales_356 = RawgentoDB::Query.num_sales_since(days_ago_356, product_ids)

      @out_of_stock_days_30 = @supplier.local_products.map{|l| [l.product_id, l.stock_items.where("qty <= ? AND date >= ?", 0, days_ago_30).count]}.to_h
      @out_of_stock_days_60 = @supplier.local_products.map{|l| [l.product_id, l.stock_items.where("qty <= ? AND date >= ?", 0, days_ago_60).count]}.to_h
      @out_of_stock_days_90 = @supplier.local_products.map{|l| [l.product_id, l.stock_items.where("qty <= ? AND date >= ?", 0, days_ago_90).count]}.to_h
      @out_of_stock_days_356 = @supplier.local_products.map{|l| [l.product_id, l.stock_items.where("qty <= ? AND date >= ?", 0, days_ago_356).count]}.to_h
      haml 'stockexplorer/stockexplorer'.to_sym, layout: !request.xhr?
    end

    # routes
    app.get  '/orders/non_remote', &show_suppliers_orders
    app.get  '/order/non_remote/:order_id', &show_supplier_order
    app.post '/order/non_remote/:order_id', &show_supplier_order_preview
    app.get  '/order/non_remote/:supplier_id/new', &create_supplier_order
    app.get  '/stockexplorer/:supplier_id', &show_stock_explorer
  end
end
