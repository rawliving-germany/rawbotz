require 'minitest'
require 'minitest/autorun'
require 'minitest/mock'

require 'ostruct'

require 'rawgento_db'
require 'rawbotz/models/stock_product'

class StockProductTest < MiniTest::Test
  include Rawbotz::Models
  include RawgentoDB

  def mock_product out_of_stock_days, first_stock_date=nil, num_days_first_sale=0
    Class.new do
      define_singleton_method(:out_of_stock_days_since) {|_arg| return out_of_stock_days}
      define_singleton_method(:first_stock_record) do
        return OpenStruct.new(created_at: first_stock_date)
      end
      define_singleton_method(:days_since_first_stock) do
        if first_record = first_stock_record
          (Date.today - first_record.created_at.to_date)
        else
          0
        end
      end
    end
  end

  def test_corrected_sales_last_30_avail
    product_mock = mock_product 0

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 20)
                                    )
    assert_equal 20, stock_product.corrected_sales_last_30
  end

  def test_corrected_sales_last_30_half_avail
    product_mock = mock_product 15

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 10)
                                    )
    assert_equal 20, stock_product.corrected_sales_last_30
  end

  def test_zero_stock_days
    product_mock = mock_product 30

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 10)
                                    )
    assert_equal 0, stock_product.corrected_sales_last_30
  end

  def test_expected_lifetime # and _base
    product_mock = mock_product 10

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 10),
                                     current_stock: 100
                                    )
    # Sold 10 times in 30 days, of which 10 were out of stock:
    #  per day = 10 sales / 20 days
    #  per 30 days = 10 sales / 20 days * 30 days
    assert_equal 200, stock_product.expected_stock_lifetime
  end

  def test_average_sales_base
    product_mock = mock_product 10, Date.today - 40, 300

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 10)
                                    )
    # Sold 10 times in 30 days, of which 10 were out of stock:
    #  per day = 10 sales / 20 days
    #  per 30 days = 10 sales / 20 days * 30 days
    assert_equal 30, stock_product.sales_per_day_base
  end

  def test_average_sales_base_60
    product_mock = mock_product 10, Date.today - 61, 200

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 10)
                                    )
    # Sold 10 times in 30 days, of which 10 were out of stock:
    #  per day = 10 sales / 20 days
    #  per 30 days = 10 sales / 20 days * 30 days
    assert_equal 30, stock_product.sales_per_day_base
    assert_equal 10/20.0, stock_product.sales_per_day
    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: ProductQty.new(200, 10),
                                     sales_last_60: ProductQty.new(200, 20)
                                    )
    assert_equal 60, stock_product.sales_per_day_base
    assert_equal 20/50.0, stock_product.sales_per_day
  end

end
