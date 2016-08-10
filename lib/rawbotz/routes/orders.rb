require 'rawbotz/routes'
require 'pdfkit'

module Rawbotz::RawbotzApp::Routing::Orders
  include RawgentoModels

  def self.registered(app)
    # app.get '/orders',             &show_orders
    show_orders = lambda do
      @orders = Order.order(created_at: :desc)
      haml "orders/index".to_sym
    end

    # app.get '/order/new',          &create_order
    create_order = lambda do
      if settings.supplier.orders.where(state: 'new').present?
        add_flash :message, "Already one Order in progress"
        @order = settings.supplier.orders.where(state: 'new').first
      else
        @order = Order.create(state: :new)
        @order.supplier     = settings.supplier
        @order.order_method = :magento

        # There is hell a lot of products missing if with remote order
        RawgentoDB::Query.understocked.each do |product_id, name, min_qty, stock|
          local_product = LocalProduct.find_by(product_id: product_id)
          if local_product.present? && local_product.supplier == settings.supplier
            @order.order_items.create(local_product: local_product,
                                      current_stock: stock,
                                      min_stock: min_qty)
          end
          # else none of our business
        end
        @order.save
        add_flash :success, "New Order created"
      end
      redirect "/order/#{@order.id}"
    end

    # app.get '/order/:id',          &show_order
    show_order = lambda do
      @order = Order.find(params[:id])
      haml 'order/view'.to_sym
    end

    # app.post '/order/:id/',         &act_on_order
    act_on_order = lambda do
      @order = Order.find(params[:id])
      params.each do |k,v|
        if k && k.start_with?("item_") && v != ""
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
        haml "order/view".to_sym
      end
    end

    # app.get '/order/:id/packlist', &show_order_packlist
    show_order_packlist = lambda do
      @order = Order.find(params[:id])
      haml "order/packlist".to_sym
    end

    # app.get  '/order/:id/packlist/pdf', &show_pdf_packlist
    show_pdf_packlist = lambda do
      attachment "packlist_order.pdf"
      @order = Order.find(params[:id])
      html = haml "order/packlist".to_sym, layout: :pdf_layout
      kit = PDFKit.new(html)

      kit.stylesheets << File.join(settings.root, "public",
                                   "pure-min.css")
      kit.stylesheets << File.join(settings.root, "public",
                                   "rawbotz.css")
      kit.stylesheets << File.join(settings.root, "public",
                                   "font-awesome-4.5.0/css/font-awesome.min.css")
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
