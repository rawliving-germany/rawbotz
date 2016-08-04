module Rawbotz
  module SalesData
    def self.sales_since day, products
      db = RawgentoDB::Query
      monthly_sales = products.map{|p| [p.product_id,
                                        db.sales_monthly_between(p.product_id,
                                        Date.today,
                                        day)]}.to_h
      # This is NOT the average!
      monthly_sales.each{|k,v| monthly_sales[k] = v.inject(0){|a,s| a + s[1].to_i}/v.length rescue 0}
    end
  end
end
