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
                                     sales_last_30: 20
                                    )
    assert_equal 20, stock_product.corrected_sales_last_30
  end

  def test_corrected_sales_last_30_half_avail
    product_mock = mock_product 15

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 10
                                    )
    assert_equal 20, stock_product.corrected_sales_last_30
  end

  def test_zero_stock_days
    product_mock = mock_product 30

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 10
                                    )
    assert_equal nil, stock_product.corrected_sales_last_30
  end

  def test_expected_lifetime # and _base
    product_mock = mock_product 10, Date.today - 100

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 10,
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
                                     sales_last_30: 10,
                                    )
    # Sold 10 times in 30 days, of which 10 were out of stock:
    #  per day = 10 sales / 20 days
    #  per 30 days = 10 sales / 20 days * 30 days
    assert_equal 30, stock_product.sales_per_day_base
  end

  def test_average_sales_base_60
    product_mock = mock_product 10, Date.today - 61, 200

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 10,
                                    )
    # Sold 10 times in 30 days, of which 10 were out of stock:
    #  per day = 10 sales / 20 days
    #  per 30 days = 10 sales / 20 days * 30 days
    assert_equal 30, stock_product.sales_per_day_base
    assert_equal 10/20.0, stock_product.sales_per_day
    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 10,
                                     sales_last_60: 20
                                    )
    assert_equal 60, stock_product.sales_per_day_base
    assert_equal 20/50.0, stock_product.sales_per_day
  end

  def test_real_sales
    product_mock = mock_product 10, Date.today - 61, 200

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 10,
                                     sales_last_60: 30,
                                     sales_last_90: 80,
                                     sales_last_365: 110
                                    )
    assert_equal 10, stock_product.real_sales(30)
    assert_equal 30, stock_product.real_sales(60)
    assert_equal 80, stock_product.real_sales(90)
    assert_equal 110, stock_product.real_sales(365)
    assert_equal 110, stock_product.real_sales(365)
    assert_raises UnsupportedNumberOfDaysError do
      stock_product.real_sales(1200)
    end
  end

  def test_corrected_sales
    product_mock = mock_product 15

    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 20,
                                     sales_last_60: 40,
                                     sales_last_90: 50,
                                     sales_last_365: 200
                                    )
    assert_equal 40, stock_product.corrected_sales_last_30
    assert_equal stock_product.corrected_sales(30),
      stock_product.corrected_sales_last_30

    stock_product.product = mock_product 30
    assert_equal 80, stock_product.corrected_sales_last_60
    assert_equal stock_product.corrected_sales(60),
      stock_product.corrected_sales_last_60

    stock_product.product = mock_product 45
    assert_equal 100, stock_product.corrected_sales_last_90
    assert_equal stock_product.corrected_sales(90),
      stock_product.corrected_sales_last_90

    stock_product.product = mock_product 0
    assert_equal 200, stock_product.corrected_sales_last_365
    assert_equal stock_product.corrected_sales(365),
      stock_product.corrected_sales_last_365

    assert_raises UnsupportedNumberOfDaysError do
      stock_product.corrected_sales(1200)
    end
  end

  def test_corrected_sales_per_day
    product_mock = mock_product 15
    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 60,
                                     sales_last_60: 360
                                    )
    assert_equal 4.0, stock_product.corrected_sales(30, per_days: 1)
    assert_equal 8.0, stock_product.corrected_sales(60, per_days: 1)
  end

  def test_corrected_sales_memoization
    product_mock = mock_product 15
    stock_product = StockProduct.new(product: product_mock,
                                     sales_last_30: 60,
                                     sales_last_60: 360
                                    )
    # Proper mocking would make expectation that caclulate-functions are called just once, along these lines
    #call_mock = MiniTest::Mock.new
    #call_mock.expect :call, 4.0, [30]

    #stock_product.stub :calculate_corrected_sales, call_mock do
    #  stock_product.calculate_corrected_sales
    #end

    #call_mock.verify


    assert_equal 120.0, stock_product.corrected_sales(30)
    assert_equal 4.0, stock_product.corrected_sales(30, per_days: 1)
    assert_equal 4.0, stock_product.corrected_sales(30, per_days: 1)
    assert_equal 8.0, stock_product.corrected_sales(60, per_days: 1)
    assert_equal 8.0, stock_product.corrected_sales(60, per_days: 1)
    assert_equal 480.0, stock_product.corrected_sales(60)
  end
end
