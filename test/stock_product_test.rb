require 'minitest'
require 'minitest/autorun'
require 'minitest/mock'

require 'rawgento_db'
require 'rawbotz/models/stock_product'

class StockProductTest < MiniTest::Test
  include Rawbotz::Models
  include RawgentoDB

  def mock_product out_of_stock_days
    Class.new do
      define_singleton_method(:out_of_stock_days_since) {|_arg| return out_of_stock_days}
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
end
