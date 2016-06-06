require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Suppliers
  include RawgentoModels

  def self.registered(app)
    # app.get  '/suppliers', &show_suppliers
    show_suppliers = lambda do
      @suppliers = Supplier.all
      haml "suppliers/index".to_sym
    end

    # app.get  '/supplier/:id', &show_supplier
    show_supplier = lambda do
      @supplier = Supplier.find(params[:id])
      haml "supplier/view".to_sym
    end

    # app.post '/supplier/:id', &update_supplier
    update_supplier = lambda do
      @supplier = Supplier.find(params[:id])
      @supplier.email = params[:email]
      @supplier.order_template = params[:order_template]
      if @supplier.save
        add_flash :success, "Supplier updated"
      else
        add_flash :error, "Supplier could not be saved"
      end
      haml "supplier/view".to_sym
    end

    app.get  '/suppliers',    &show_suppliers
    app.get  '/supplier/:id', &show_supplier
    app.post '/supplier/:id', &update_supplier
  end
end
