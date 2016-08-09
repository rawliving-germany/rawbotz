module Rawbotz
  module Models
    module StockProductFactory
      include RawgentoModels
      include RawgentoDB

      def self.create suppliers
        product_ids = LocalProduct.where(supplier_id: suppliers.map(&:id), active: true).pluck(:product_id)

        sales_30 = Query.num_sales_since(Date.today - 30, product_ids)
        sales_60 = Query.num_sales_since(Date.today - 60, product_ids)
        sales_90 = Query.num_sales_since(Date.today - 90, product_ids)
        sales_365 = Query.num_sales_since(Date.today - 365, product_ids)

        beginning_of_time = StockItem.order(created_at: :asc).first.created_at.to_date

        sales       = Query.num_sales_since(beginning_of_time, product_ids)
        first_sales = Query.first_sales(product_ids)
        # Default to today instead of nil date
        first_sales.default = Date.today
        stock = {}

        Query.stock.each {|s| stock[s.product_id] = s.qty}
        product_ids.map do |product_id|
          StockProduct.new(product: LocalProduct.find_by(product_id: product_id),
                           current_stock: stock[product_id],
                           sales_last_30: sales_30[product_id],
                           sales_last_60: sales_60[product_id],
                           sales_last_90: sales_90[product_id],
                           sales_last_365: sales_365[product_id],
                           num_days_first_sale: Date.today - first_sales[product_id].to_date
                          )
        end
      end
    end
  end
end
