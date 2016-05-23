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
  end
end
