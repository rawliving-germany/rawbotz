require 'active_model'

module Rawbotz
  module Models
    class Stock
      include ActiveModel::Model # convenience

      def self.all_stock
        stock = {}
        RawgentoDB::Query.stock.each {|s| stock[s.product_id] = s.qty}
        stock
      end

      # Returns a map of product_id to RawgentoDB::ProductQty .
      def self.stock_for product_ids
        stock = {}
        # Find ruby idiomatic way to do that (probably map{}.to_h)
        RawgentoDB::Query.stock_for(product_ids).each do |s|
          stock[s.product_id] = s.qty
        end
        stock
      end
    end
  end
end
