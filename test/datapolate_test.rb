require 'minitest'
require 'minitest/autorun'

require 'rawbotz/datapolate'

#require File.expand_path '../test_helper.rb', __FILE__

class DatapolateTest < MiniTest::Test
  Stock = Struct.new(:date, :qty)
  def test_dateminmax
    sales = [["2014-08-10", 80], ["2014-11-01", 90]]
    stock = [Stock.new(Date.civil(2014, 10, 10), 100),
             Stock.new(Date.civil(2015,11,1), 200)]
    assert_equal [Date.civil(2014,8,10), Date.civil(2015,11,1)],
      Rawbotz::Datapolate.date_minmax(sales, stock)

    empty_sales = []
    assert_equal [Date.civil(2014,10,10), Date.civil(2015,11,1)],
      Rawbotz::Datapolate.date_minmax(empty_sales, stock)

    empty_stock = []
    sales = [["2014-08-10", 80], ["2014-11-01", 90]]
    assert_equal [Date.civil(2014,8,10), Date.civil(2014,11,1)],
      Rawbotz::Datapolate.date_minmax(sales, empty_stock)

    assert_equal [nil, nil],
      Rawbotz::Datapolate.date_minmax(empty_sales, empty_stock)
  end

  def test_explode_days
    days = Rawbotz::Datapolate.explode_days Date.civil(2014, 10, 10),
      Date.civil(2014,10,14)
    assert_equal [Date.civil(2014, 10, 10),
                  Date.civil(2014, 10, 11),
                  Date.civil(2014, 10, 12),
                  Date.civil(2014, 10, 13),
                  Date.civil(2014, 10, 14)],
                 days
  end

  def test_datapolation
    # Deal with month/day based values, step-'interpolate' them
    sales = [["2014-10-10", 80], ["2014-10-10", 90]]
    stock = [Stock.new(Date.civil(2014, 10, 10), 100),
             Stock.new(Date.civil(2014, 10,  12), 200)]
    data = Rawbotz::Datapolate.create_data sales, stock
    assert_equal [{label: "2014-10-10", stock: 100, sales: 80},
                  {label: "2014-11-01", stock: 200, sales: 90}], data
  end
end
