module Rawbotz
  module Datapolate
    def self.date_minmax sales, stock
      sales.each{|sale| sale[0] = Date.strptime(sale[0])}
      sales_mm = sales.minmax_by{|s| s[0]}
      stock_mm = stock.minmax_by{|s| s.date}
      [[sales_mm[0][0], stock_mm[0].date].min, [sales_mm[1][0], stock_mm[1].date].max]
    end

    def self.explode_days min_date, max_date
      (min_date..max_date).to_a
    end

    def self.create_data sales, stock
      # from [date, sales] and [date, stock] create realistic list
      from_date, to_date = date_minmax sales, stock
    end
  end
end
