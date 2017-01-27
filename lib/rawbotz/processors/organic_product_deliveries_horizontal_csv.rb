require 'csv'

module Rawbotz
  class OrganicProductDeliveriesHorizontalCSV
    include RawgentoModels

    def self.generate supplier
      # Collect relevant data
      products = []#ordered hash
      orders = []

      # product as row, order as col, by date
      supplier.orders.where(state: :stocked).order(stocked_at: :asc).each do |order|
        if order.order_items.includes(:local_product).where('local_products.organic = ?', true).where("num_stocked > 0").present?
          orders << order
        end
      end

      headings = headings(orders)
      CSV.generate do |csv|
        csv << headings
        supplier.local_products.where(organic: true). each do |product|
          csv << row(product, orders)
        end
      end
    end

    private

    def self.headings orders
      ["product", "product_id"] | orders.map{|o| order_heading(o)}.flatten
    end

    def self.row product, orders
      stocked_values = orders.map{|o| product.order_items.find_by(order_id: o.id)&.num_stocked}
      [product.name, product.product_id, *stocked_values]
    end

    def self.order_heading order
      ["#{order.stocked_at}, bill #{order.remote_order_id}"]
    end
  end
end
