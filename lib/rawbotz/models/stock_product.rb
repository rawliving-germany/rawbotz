require 'active_model'

module Rawbotz
  module Models
    class UnsupportedNumberOfDaysError < StandardError
    end

    class StockProduct
      include ActiveModel::Model # convenience

      attr_accessor :product, :current_stock,
        :sales_last_30, :sales_last_60, :sales_last_90, :sales_last_365,
        :num_days_first_sale, :mem_corrected_sales

      delegate :name, to: :product

      def expected_stock_lifetime
        if @current_stock.to_i == 0 || sales_per_day.nil? || sales_per_day == 0.0
          return 0.0
        end
        @current_stock / sales_per_day
      end

      def real_sales num_days
        if num_days == 30
          @sales_last_30
        elsif num_days == 60
          @sales_last_60
        elsif num_days == 90
          @sales_last_90
        elsif num_days == 365
          @sales_last_365
        else
          raise UnsupportedNumberOfDaysError
        end
      end

      def corrected_sales num_days, per_days: num_days
        factor = num_days.to_f / per_days
        sales = nil
        if num_days == 30
          sales = corrected_sales_last_30
        elsif num_days == 60
          sales = corrected_sales_last_60
        elsif num_days == 90
          sales = corrected_sales_last_90
        elsif num_days == 365
          sales = corrected_sales_last_365
        else
          raise UnsupportedNumberOfDaysError
        end
        return nil if sales.nil?
        sales / factor
      end

      # We should also extrapolate (out of-) stock days!

      def corrected_sales_last_30
        @mem_corrected_sales ||= {}
        @mem_corrected_sales[30] ||= calculate_corrected_sales(30)
      end

      def corrected_sales_last_60
        @mem_corrected_sales ||= {}
        @mem_corrected_sales[60] ||= calculate_corrected_sales(60)
      end

      def corrected_sales_last_90
        @mem_corrected_sales ||= {}
        @mem_corrected_sales[90] ||= calculate_corrected_sales(90)
      end

      def corrected_sales_last_365
        @mem_corrected_sales ||= {}
        @mem_corrected_sales[365] ||= calculate_corrected_sales(365)
      end

      def days_since_first_stock_date
        #@mem_days_since_first_stock_date ||=
        return 0 if !@product.first_stock_record.present?
        first_stock_date = @product.first_stock_record.created_at.to_date
        Date.today - first_stock_date
      end

      def out_of_stock_days num_days
        @product.out_of_stock_days_since(Date.today - num_days)
      end

      def sales_per_day
        case sales_per_day_base
        when 365
          @sales_last_365 / days_in_stock(365).to_f
        when 90
          @sales_last_90 / days_in_stock(90).to_f
        when 60
          @sales_last_60 / days_in_stock(60).to_f
        when 30
          return nil if @sales_last_30.nil?
          return nil if days_in_stock(30).to_i == 0
          @sales_last_30 / days_in_stock(30).to_f
        else
          raise UnsupportedNumberOfDaysError
        end
      end

      def sales_per_day_base
        product_days_first_stock = @product.days_since_first_stock
        #first saleproduct_days_first_stock = @product.days_since_first_stock
        if @sales_last_365.present? && product_days_first_stock >= 365 && num_days_first_sale >= 365 && days_in_stock(365) != 0
          return 365
        elsif @sales_last_90.present? && product_days_first_stock >= 90 && num_days_first_sale >= 90 && days_in_stock(90) != 0
          return 90
        elsif @sales_last_60.present? && product_days_first_stock >= 60 && num_days_first_sale >= 60 && days_in_stock(60) != 0
          return 60
        #elsif @sales_last_30.present?
        else
          # today - last sale ?
          return 30
        end
      end

      private

      # For easier memoization
      def calculate_corrected_sales num_days
        return nil if days_in_stock(num_days).to_i == 0
        return nil if real_sales(num_days).nil?
        if days_in_stock(num_days).to_i != 0
          real_sales(num_days) * factor_days_in_stock(num_days)
        else
          0
        end
      end

      # From the last num_days, how many days was the product in stock?
      def days_in_stock num_days
        num_days - out_of_stock_days(num_days)
      end

      # Factor to extrapolate sales, e.g. 1/2 of time out of stock makes factor 2.0
      def factor_days_in_stock num_days
        num_days.to_f / days_in_stock(num_days)
      end
    end
  end
end
