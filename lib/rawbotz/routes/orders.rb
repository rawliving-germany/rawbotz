require 'rawbotz/routes'
require 'pdfkit'

module Rawbotz::RawbotzApp::Routing::Orders
  include Rawbotz
  include RawgentoModels

  def self.registered(app)
    # app.get '/orders',             &show_orders
    show_orders = lambda do
      @orders = Order.order(created_at: :desc).all
      haml "orders/index".to_sym
    end

    # app.get '/order/new',          &create_order
    create_order = lambda do
      if settings.supplier.orders.where(state: 'new').present?
        add_flash :message, "Already one Order in progress"
        @order = settings.supplier.orders.where(state: 'new').first
        redirect "/order/#{@order.id}"
      end

      order_creator = Processors::OrderCreator.new(settings.supplier)
      order_creator.process!
      @order = order_creator.order

      if order_creator.succeeded?
        add_flash :success, order_creator.messages
        redirect "/order/#{@order.id}"
      else
        add_flash :error, order_creator.messages
        redirect back
      end
    end

    # app.get '/order/:id',          &show_order
    show_order = lambda do
      # Template does depend on Orders state.
      @order    = Order.includes(order_items: [:local_product]).find(params[:id])
      @supplier = @order.supplier


      if @order.state == "new"
        # Do we need to rescue from Factory usage ?
        begin
          stock_products = Models::StockProductFactory.create @supplier
          @stock_products_hash = stock_products.map{|s| [s.product.id, s]}.to_h

          #@products = @order.order_items.map{|oi| oi.local_product}
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          @stock_products_hash = {}
          add_flash :error, "Cannot connect to MySQL database (#{e.message})"
        end
        haml "order/view_new".to_sym
      else
        @stock = {}
        # TODO: for remote and linked orders, show 'refund'-values
        begin
          @stock = Rawbotz::Models::Stock.all_stock
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          add_flash :error, "Cannot connect to MySQL database (#{e.message})"
        end
        haml "order/view".to_sym
      end
    end

    # app.post '/order/:id/',         &act_on_order
    act_on_order = lambda do
      @order = Order.find(params[:id])
      params.each do |k,v|
        if k && k.start_with?("item_") && v != ""
          # @order.order_items.find ?
          OrderItem.find(k[5..-1]).update(num_wished: v.to_i)
        end
      end
      @order.internal_comment = params[:internal_comment]
      @order.save

      if params['action'] == 'order'
        @order.update(state: :queued)
        add_flash :success, 'Order queued'
        redirect '/orders'
      elsif params['action'] == 'delete'
        @order.update(state: :deleted)
        add_flash :success, 'Order marked deleted'
        redirect '/orders'
      else
        @stock = {}
        begin
          RawgentoDB::Query.stock.each {|s| @stock[s.product_id] = s.qty}
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          add_flash :error, "Cannot connect to MySQL database (#{e.message})"
        end
        haml "order/view".to_sym
      end
    end

    # app.get '/order/:id/packlist', &show_order_packlist
    show_order_packlist = lambda do
      @order = Order.find(params[:id])
      @orphans = []
      @refunds = {}
      if @order.supplier == settings.supplier && @order.remote_order_link.present?
        order_linker = Processors::OrderLinker.new @order
        # TODO will be: process!
        order_linker.link!
        @orphans = order_linker.orphans
        @refunds = order_linker.refunds
      end
      haml "order/packlist".to_sym
    end

    # app.get  '/order/:id/packlist/pdf', &show_pdf_packlist
    show_pdf_packlist = lambda do
      attachment "packlist_order.pdf"
      @order = Order.find(params[:id])
      html = haml "order/packlist.pdf".to_sym, layout: :pdf_layout
      PDFKit.configure do |config|
        config.verbose = false
        config.default_options[:quiet] = true
      end

      kit = PDFKit.new(html)

      kit.stylesheets << File.join(settings.root, "public",
                                   "pure-min.css")
      kit.stylesheets << File.join(settings.root, "public",
                                   "rawbotz.css")
      # This would need more resources (base64 encoded woff?)
      #kit.stylesheets << File.join(settings.root, "public",
      #                             "font-awesome-4.5.0/css/font-awesome.min.css")
      kit.stylesheets << File.join(settings.root, "public",
                                   "jui/jquery-ui.min.css")
      kit.to_pdf
    end

    # routes
    app.get  '/orders',             &show_orders
    app.get  '/order/new',          &create_order
    app.get  '/order/:id',          &show_order
    app.post '/order/:id',          &act_on_order
    app.get  '/order/:id/packlist', &show_order_packlist
    app.get  '/order/:id/packlist/pdf', &show_pdf_packlist
  end
end
