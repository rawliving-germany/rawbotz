module Rawbotz
  module Models
    module StockProductFactory
      include RawgentoModels
      include RawgentoDB

      # Query.num_sales_since will return nil even if the product
      # was actually available (but not sold).  Put a zero there instead.
      def self.set_0_sales num_days, sales_hash, first_sales
        first_sales.keys.each do |pid|
          if !sales_hash[pid] && (Date.today - num_days) >= first_sales[pid]
            sales_hash[pid] = ProductQty.new(pid, 0)
          end
        end
      end

      def self.create_single product
        product_id = product.product_id
        sales_30  = Query.num_sales_since(Date.today - 30,  product_id)
        sales_60  = Query.num_sales_since(Date.today - 60,  product_id)
        sales_90  = Query.num_sales_since(Date.today - 90,  product_id)
        sales_365 = Query.num_sales_since(Date.today - 365, product_id)

        beginning_of_time = StockItem.order(created_at: :asc).pluck(:created_at).first.to_date

        sales       = Query.num_sales_since(beginning_of_time, product_id)
        first_sales = Query.first_sales(product_id)
        # Default to today instead of nil date
        first_sales.default = Date.today

        set_0_sales(30, sales_30, first_sales)
        set_0_sales(60, sales_60, first_sales)
        set_0_sales(90, sales_90, first_sales)
        set_0_sales(365, sales_365, first_sales)

        # stock product has trouble when empty values ...
        stock = Query.stock.find {|s| s.product_id = product_id}.qty
        StockProduct.new(product: LocalProduct.unscoped.find_by(product_id: product_id),
                         current_stock: stock[product_id],
                         sales_last_30: sales_30[product_id]&.qty,
                         sales_last_60: sales_60[product_id]&.qty,
                         sales_last_90: sales_90[product_id]&.qty,
                         sales_last_365: sales_365[product_id]&.qty,
                         num_days_first_sale: Date.today - first_sales[product_id].to_date
                        )

      end

      def self.create suppliers
        product_ids = LocalProduct.unscoped.where(supplier_id: [*suppliers].map(&:id), active: true).pluck(:product_id)

        sales_30  = Query.num_sales_since(Date.today - 30,  product_ids)
        sales_60  = Query.num_sales_since(Date.today - 60,  product_ids)
        sales_90  = Query.num_sales_since(Date.today - 90,  product_ids)
        sales_365 = Query.num_sales_since(Date.today - 365, product_ids)

        beginning_of_time = StockItem.order(created_at: :asc).first.created_at.to_date

        sales       = Query.num_sales_since(beginning_of_time, product_ids)
        first_sales = Query.first_sales(product_ids)
        # Default to today instead of nil date
        first_sales.default = Date.today
        set_0_sales(30, sales_30, first_sales)
        set_0_sales(60, sales_60, first_sales)
        set_0_sales(90, sales_90, first_sales)
        set_0_sales(365, sales_365, first_sales)

        stock = {}
        Query.stock.each {|s| stock[s.product_id] = s.qty}

        product_ids.map do |product_id|
          local_product = LocalProduct.unscoped.find_by(product_id: product_id)
          StockProduct.new(product: local_product,
                           current_stock: stock[product_id],
                           sales_last_30: sales_30[product_id]&.qty,
                           sales_last_60: sales_60[product_id]&.qty,
                           sales_last_90: sales_90[product_id]&.qty,
                           sales_last_365: sales_365[product_id]&.qty,
                           num_days_first_sale: Date.today - first_sales[product_id].to_date
                          )
        end
      end
    end
  end
end
