require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Orders
  include RawgentoModels

  def self.registered(app)
    # app.get '/orders',             &show_orders
    show_orders = lambda do
      @orders = Order.where("supplier_id IS NULL OR supplier_id = %d" % settings.supplier.id).order(created_at: :desc)
      haml "orders/index".to_sym
    end

    # app.get '/order/new',          &create_order
    create_order = lambda do
      if Order.current.present?
        add_flash :message, "Already one Order in progress"
        @order = Order.current
      else
        @order = Order.create(state: :new)
        @order.supplier = settings.supplier

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

    app.get  '/orders',             &show_orders
    app.get  '/order/new',          &create_order
    app.get  '/order/:id',          &show_order
    app.post '/order/:id/',         &act_on_order
    app.get  '/order/:id/packlist', &show_order_packlist
  end
end
