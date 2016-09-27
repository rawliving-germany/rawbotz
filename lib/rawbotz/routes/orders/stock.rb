require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Orders::Stock
  include RawgentoModels

  def self.registered(app)

    # app.get  '/order/:id/stock',    &show_stock_order
    show_stock_order = lambda do
      @order = Order.find(params[:id])
      @refunds = {}
      if @order.supplier == settings.supplier && @order.remote_order_link.blank?
        add_flash :message, "You need to select a remote order"
        redirect "/order/#{@order.id}/link_to_remote"
      else
        if @order.supplier == settings.supplier
          order_linker = Rawbotz::OrderLinker.new @order
          # TODO will be: process!
          order_linker.link!
          @orphans = order_linker.orphans
          @refunds = order_linker.refunds
        end
        haml "order/stock".to_sym
      end
    end

    # app.post '/order/:id/stock',    &stock_order
    stock_order = lambda do
      @order = Order.find(params[:id])

      @order.remote_order_id   = params[:remote_order_id]
      @order.remote_order_link = params[:remote_order_link]

      stock_processor = Rawbotz::Processors::StockProcessor.new @order, params
      errors = stock_processor.process!

      if errors.empty?
        add_flash :success, "Stocked this order"
      else
        errors.each{|e| add_flash :error, e}
      end

      @refunds = {}
      if @order.supplier == settings.supplier
        order_linker = Rawbotz::OrderLinker.new @order
        # TODO will be: process!
        order_linker.link!
        @orphans = order_linker.orphans
        @refunds = order_linker.refunds
      end

      haml "order/stock".to_sym
    end

    # app.get  '/order/:id/link_to_remote',   &show_link_to_remote_order
    show_link_to_remote_order = lambda do
      @order = Order.find(params[:id])
      @last_orders = Rawbotz.mech.last_orders
      haml "order/link_to_remote".to_sym
    end

    # app.post '/order/:id/link_to_remote', &link_to_remote_order
    link_to_remote_order = lambda do
      @order = Order.find(params[:id])
      @order.remote_order_id   = params[:remote_order_id]
      @order.remote_order_link = params[:remote_order_link]
      @order.save
      redirect "/order/#{@order.id}/stock"
    end

    # routes
    app.get  '/order/:id/stock',    &show_stock_order
    app.post '/order/:id/stock',    &stock_order
    app.get  '/order/:id/link_to_remote', &show_link_to_remote_order
    app.post '/order/:id/link_to_remote', &link_to_remote_order
  end
end
