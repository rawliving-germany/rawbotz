require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Suppliers::Orders
  include RawgentoModels

  def self.registered(app)
    # app.get  '/suppliers/orders',     &show_table
    show_table = lambda do
      @supplier = Supplier.find(params[:id])
      haml "supplier/orders/table".to_sym, layout: request.xhr? ? "xhr_layout".to_sym : true
    end

    # app.get  '/suppliers/orders.csv', &csv
    csv = lambda do
      @supplier = Supplier.find(params[:id])
      file_name = ActiveSupport::Inflector::parameterize(@supplier.name)
      content_type "application/csv"
      attachment   "organic_deliveries-#{file_name}.csv"
      Rawbotz::OrganicProductDeliveriesHorizontalCSV.generate @supplier
    end

    # routes
    app.get  '/supplier/:id/organic_deliveries',     &show_table
    app.get  '/supplier/:id/organic_deliveries.csv', &csv
  end
end
