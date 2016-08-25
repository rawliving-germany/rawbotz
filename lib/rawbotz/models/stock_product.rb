require 'active_model'

module Rawbotz
  module Models
    class UnsupportedNumberOfDaysError < StandardError
    end

    class StockProduct
      include ActiveModel::Model # convenience

      attr_accessor :product, :current_stock,
        :sales_last_30, :sales_last_60, :sales_last_90, :sales_last_365,
        :num_days_first_sale

      delegate :name, to: :product

      def expected_stock_lifetime
        # division by zero?
        if @current_stock.to_i == 0 || sales_per_day == 0.0
          return 0.0
        end
        @current_stock / sales_per_day
      end

      def real_sales num_days
        if num_days == 30
          @sales_last_30.qty
        elsif num_days == 60
          @sales_last_60.qty
        elsif num_days == 90
          @sales_last_90.qty
        elsif num_days == 365
          @sales_last_365.qty
        else
          raise UnsupportedNumberOfDaysError
        end
      end

      def corrected_sales num_days
        if num_days == 30
          corrected_sales_last_30
        elsif num_days == 60
          corrected_sales_last_60
        elsif num_days == 90
          corrected_sales_last_90
        elsif num_days == 365
          corrected_sales_last_365
        else
          raise UnsupportedNumberOfDaysError
        end
      end

      # We should also extrapolate (out of-) stock days!

      def corrected_sales_last_30
        if @sales_last_30.present? && days_in_stock(30).to_i != 0
          @sales_last_30.qty * factor_days_in_stock(30)
        else
          0
        end
      end

      def corrected_sales_last_60
        if @sales_last_60.present? && days_in_stock(60).to_i != 0
          @sales_last_60.qty * factor_days_in_stock(60)
        else
          0
        end
      end

      def corrected_sales_last_90
        if @sales_last_90.present? && days_in_stock(90).to_i != 0
          @sales_last_90.qty * factor_days_in_stock(90)
        else
          0
        end
      end

      def corrected_sales_last_365
        if @sales_last_365.present? && days_in_stock(365).to_i != 0
          @sales_last_365.qty * factor_days_in_stock(365)
        else
          0
        end
      end

      def days_since_first_stock_date
        first_stock_date = @product.first_stock_record.try(:created_at).try(:to_date)
        return 0 if !first_stock_date.present?
        Date.today - first_stock_date
      end

      def out_of_stock_days num_days
        @product.out_of_stock_days_since(Date.today - num_days)
      end

      def sales_per_day
        if false
        #if @sales_last_365.present?
        #  @sales_last_365.qty / days_in_stock(365).to_f
        #elsif @sales_last_90.present?
        #  @sales_last_90.qty / days_in_stock(90).to_f
        elsif @sales_last_60.present?
          return 0 if days_in_stock(60) == 60.0
           @sales_last_60.qty / days_in_stock(60).to_f
        elsif @sales_last_30.present?
          if days_in_stock(30) != 0
            @sales_last_30.qty / days_in_stock(30).to_f
          else
            0
          end
        else
          0
        end
      end

      def sales_per_day_base
        product_days_first_stock = @product.days_since_first_stock
        if @sales_last_365.present? && product_days_first_stock >= 365
          return 365
        elsif @sales_last_90.present? && product_days_first_stock >= 90
          return 90
        elsif @sales_last_60.present? && product_days_first_stock >= 60
          return 60
        #elsif @sales_last_30.present?
        else
          # today - last sale ?
          return 30
        end
      end

      private

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
