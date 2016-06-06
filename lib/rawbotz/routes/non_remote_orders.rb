require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::NonRemoteOrders
  include RawgentoModels

  def self.registered(app)
    # app.get  '/orders/non_remote', &show_suppliers_orders
    show_suppliers_orders = lambda do
      haml "orders/non_remotes".to_sym
    end

    # app.get  '/order/non_remote/:supplier_id', &show_supplier_order
    show_supplier_order = lambda do
      @supplier = Supplier.find(params[:supplier_id])
      if @supplier.order_template.to_s == ""
        add_flash :warning, "You need to set the mailer template to order from this supplier"
        redirect "/supplier/#{@supplier.id}"
      else
        @products = LocalProduct.supplied_by(@supplier)
        haml "order/non_remote".to_sym
      end
    end

    # app.post '/order/non_remote/:supplier_id', &show_supplier_order_preview
    show_supplier_order_preview = lambda do
      @supplier = Supplier.find(params[:supplier_id])
      @products = @supplier.local_products

      order = {supplier: @supplier, order_items: []}
      params.select{|p| p.start_with?("item_")}.each do |p, val|
        if val && val.to_i > 0
          qty = val.to_i
          product = LocalProduct.find(p[5..-1])
          order[:order_items] << {num_wished: qty, local_product: product}
        end
      end
      @mail_preview = Rawbotz::MailTemplate.consume @supplier.order_template, order
      haml "order/non_remote".to_sym
    end

    app.get  '/orders/non_remote', &show_suppliers_orders
    app.get  '/order/non_remote/:supplier_id', &show_supplier_order
    app.post '/order/non_remote/:supplier_id', &show_supplier_order_preview
  end
end