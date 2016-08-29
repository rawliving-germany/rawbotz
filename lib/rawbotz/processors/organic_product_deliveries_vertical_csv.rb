require 'csv'

module Rawbotz
  class OrganicProductDeliveriesCSV
    include RawgentoModels

    def self.generate
      CSV.generate do |csv|
        csv << headings
        Supplier.find_each do |supplier|
          supplier_lines supplier, csv
        end
      end
    end

    private

    def self.headings
      ["product", "qty stocked", "stock date",
       "order date", "order nr", "supplier"]
    end

    def self.supplier_lines supplier, csv
      supplier.orders.find_each do |order|
        # only organic (includes(:local_product).where('local_product.organic = ?', true)
        if order.order_items.includes(:local_product).where('local_products.organic = ?', true).where("num_stocked > 0").present?
          order_lines order, csv
        end
      end
    end

    def self.order_lines order, csv
      csv << ["Order #{order.remote_order_id} from #{order.supplier.name}"]
      order.order_items.includes(:local_product).where('local_products.organic = ?', true).where("num_stocked > 0").each do |item|
        csv << order_item_line(item)
      end
    end

    def self.order_item_line item
      [item.local_product.name,
       item.num_stocked,
       item.order.stocked_at,
       item.order.ordered_at,
       item.order.remote_order_id,
       item.order.supplier.name]
    end
  end
end
