require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Suppliers::Orders
  include RawgentoModels

  def self.registered(app)
    # app.get  '/suppliers/orders',     &show_table
    show_table = lambda do
      haml "supplier/orders/table".to_sym
    end

    # app.get  '/suppliers/orders.csv', &csv
    csv = lambda do
      content_type "application/csv"
      attachment   "organic_deliveries.csv"
      Rawbotz::OrganicProductDeliveriesCSV.generate
    end

    # routes
    app.get  '/suppliers/orders',     &show_table
    app.get  '/suppliers/orders.csv', &csv
  end
end
