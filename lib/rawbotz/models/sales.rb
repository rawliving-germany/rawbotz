require 'active_model'

module Rawbotz
  module Models
    class Sales
      include ActiveModel::Model # convenience

      def self.daily_since product_id, num_days=30, settings
        RawgentoDB::Query.sales_daily_between(product_id,
          Date.today, Date.today - num_days)
      end

      def self.monthly_since product_id, num_months=12, settings
        # Todo create a date num_month month ago (vs x*30)
        RawgentoDB::Query.sales_monthly_between(product_id,
          Date.today, Date.today - (num_months * 30)).uniq
      end
    end
  end
end
