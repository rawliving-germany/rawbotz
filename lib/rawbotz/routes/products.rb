require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Products
  include RawgentoModels

  def self.registered(app)
    show_products = lambda do
      @products = LocalProduct
      @suppliers = Supplier.all
      haml "products/index".to_sym
    end

    show_product = lambda do
      settings = RawgentoDB.settings(Rawbotz.conf_file_path)
      @product = LocalProduct.unscoped.find(params[:id])
      begin
        @sales = RawgentoDB::Query.sales_daily_between(@product.product_id,
                                                       Date.today,
                                                       Date.today - 30,
                                                       settings)
      rescue
        @sales = []
        add_flash :error, 'Cannot connect to MySQL database'
      end
      @plot_data = Rawbotz::Datapolate.create_data @sales, @product.stock_items
      haml "product/view".to_sym
    end

    hide_product = lambda do
      @product = RawgentoModels::LocalProduct.find(params[:id])
      @product.active = false
      @product.save

      add_flash :success, "Product '#{@product.name}' is now hidden"
      redirect back
    end

    unhide_product = lambda do
      @product = RawgentoModels::LocalProduct.unscoped.find(params[:id])
      @product.active = true
      @product.save

      add_flash :success, "Product '#{@product.name}' is now not hidden anymore"
      redirect back
    end

    app.get  '/products',           &show_products
    app.get  '/product/:id',        &show_product
    app.post '/product/:id/hide',   &hide_product
    app.post '/product/:id/unhide', &unhide_product
  end
end
