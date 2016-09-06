require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Stock
  include RawgentoModels

  def self.registered(app)

    # app.get  '/stock',        &show_stock
    show_stock = lambda do
      @suppliers  = Supplier.where.not(id: settings.supplier.id).order(:name).all
      begin
        @stock_products = Rawbotz::Models::StockProductFactory.create @suppliers
      rescue Exception => e
        @stock_products = []
        STDERR.puts e.message
        STDERR.puts e.backtrace
        add_flash :error, "Error: #{e.message}"
      end

      haml "stock/index".to_sym
    end

    # app.get  '/stock/alerts', &show_stock_alerts
    show_stock_alerts = lambda do
      @suppliers  = Supplier.where.not(id: settings.supplier.id).order(:name).all
      begin
        @stock_products = Rawbotz::Models::StockProductFactory.create @suppliers
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        @stock_products = []
        add_flash :error, "Error: #{e.message}"
      end

      mis_stocked_product_ids = RawgentoDB::Query.wrongly_not_in_stock
      @wrongly_out_of_stocks  = LocalProduct.where(product_id: mis_stocked_product_ids)
      @stock = Rawbotz::Models::Stock.stock_for mis_stocked_product_ids

      haml "stock/index".to_sym
    end

    # app.get  '/stock/warnings', &show_stock_warnings
    show_stock_warnings = lambda do
      @suppliers  = Supplier.where.not(id: settings.supplier.id).order(:name).all
      begin
        @stock_products = Rawbotz::Models::StockProductFactory.create @suppliers
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        @stock_products = []
        add_flash :error, "Error: #{e.message}"
      end

      @stock_products.delete_if {|s| s.expected_stock_lifetime > 10 }

      haml "stock/index".to_sym
    end


    # routes
    app.get  '/stock',          &show_stock
    app.get  '/stock/alerts',   &show_stock_alerts
    app.get  '/stock/warnings', &show_stock_warnings
  end
end
