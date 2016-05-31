require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Orders
  include RawgentoModels

  def self.registered(app)
    show_orders = lambda do
      @orders = Order.where("supplier_id IS NULL OR supplier_id = %d" % settings.supplier.id).order(created_at: :desc)
      haml "orders/index".to_sym
    end

    show_order = lambda do
      @order = Order.find(params[:id])
      haml 'order/view'.to_sym
    end

    show_order_packlist = lambda do
      @order = Order.find(params[:id])
      haml "order/packlist".to_sym
    end

    app.get '/orders',             &show_orders
    app.get '/order/:id',          &show_order
    app.get '/order/:id/packlist', &show_order_packlist
  end
end
