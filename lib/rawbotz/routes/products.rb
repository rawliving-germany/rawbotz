require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Products
  include Rawbotz
  include RawgentoModels

  def self.registered(app)
    # app.get  '/products',           &show_products
    show_products = lambda do
      @products = LocalProduct.includes(:supplier, :remote_product)
      @suppliers = Supplier.includes(:local_products).order(:name).all
      haml "products/index".to_sym
    end

    # app.post '/products/search',    &search_products
    search_products = lambda do
      @term = params[:term]
      if request.xhr?
        @products = LocalProduct.name_ilike(@term).limit(20)
          .pluck(:name, :id)
        @products.map{|p| {name: p[0], product_id: p[1]}}.to_json
      else
        search = Models::Search.new(term: @term, fields: :all)
        @products = search.perform!
        haml "products/search_results".to_sym
      end
    end

    # app.get  '/product/:id',        &show_product
    show_product = lambda do
      settings = RawgentoDB.settings(Rawbotz.conf_file_path)
      @product = LocalProduct.unscoped.includes(:supplier).find(params[:id])
      begin
        product_id = @product.product_id
        @sales = Models::Sales.daily_since product_id
        @sales_monthly = Models::Sales.monthly_since product_id
        @stock_product = Models::StockProductFactory.create_single @product
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        @sales = []
        @sales_monthly = []
        add_flash :error, "Cannot connect to MySQL database/ #{e.message}"
      end
      @plot_data = Rawbotz::Datapolate.create_data @sales, @product.stock_items.where(created_at: (Date.today - 30)..Date.today)
      haml "product/view".to_sym
    end

    # app.get  '/product/:id/stock_sales_plot', &show_product
    show_product_stock_sales_plot = lambda do
      @product = LocalProduct.unscoped.find(params[:id])
      begin
        @sales = Models::Sales.daily_since(@product.product_id)
      rescue
        @sales = []
        add_flash :error, 'Cannot connect to MySQL database'
      end
      @plot_data = Rawbotz::Datapolate.create_data @sales, @product.stock_items
      haml "product/_stock_sales_plot".to_sym, layout: :thin_layout, locals: {plot_data: @plot_data}
    end

    # app.post '/product/:id/hide',   &hide_product
    hide_product = lambda do
      @product = RawgentoModels::LocalProduct.find(params[:id])
      @product.hidden = true
      @product.save

      add_flash :success, "Product '#{@product.name}' is now hidden"
      redirect back
    end

    # app.post '/product/:id/unhide', &unhide_product
    unhide_product = lambda do
      @product = RawgentoModels::LocalProduct.unscoped.find(params[:id])
      @product.hidden = false
      @product.save

      add_flash :success, "Product '#{@product.name}' is now not hidden anymore"
      redirect back
    end

    # app.get  '/remote_products',    &show_remote_products
    show_remote_products = lambda do
      @products = RawgentoModels::RemoteProduct.all
      haml "remote_products/index".to_sym
    end

    # app.post '/remote_products/search', &search_remote_products
    search_remote_products = lambda do
      @products = RemoteProduct.supplied_by(settings.supplier)
        .ilike(params[:term]).limit(20).pluck(:name, :id)
      @products.map do |p|
        {name: p[0], product_id: p[1]}
      end.to_json
    end

    # app.get  '/remote_product/:id',  &show_remote_product
    show_remote_product = lambda do
      @product = RawgentoModels::RemoteProduct.find(params[:id])
      haml "remote_product/view".to_sym
    end

    app.get  '/products',                     &show_products
    app.post '/products/search',              &search_products
    app.get  '/product/:id',                  &show_product
    app.get  '/product/:id/stock_sales_plot', &show_product_stock_sales_plot
    app.post '/product/:id/hide',             &hide_product
    app.post '/product/:id/unhide',           &unhide_product

    app.get  '/remote_products',        &show_remote_products
    app.post '/remote_products/search', &search_remote_products
    app.get  '/remote_product/:id',     &show_remote_product
  end
end
