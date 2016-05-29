module Rawbotz
  module Datapolate
    def self.date_minmax sales, stock
      #sales.each{|sale| sale[0] = Date.strptime(sale[0])}
      sales_first, sales_last = sales.minmax_by{|s| s[0]}
      stock_first, stock_last = stock.minmax_by{|s| s.date}
      first_dates = []
      first_dates << sales_first[0]   if !sales_first.nil?
      first_dates << stock_first.date if !stock_first.nil?

      last_dates = []
      last_dates << sales_last[0]   if !sales_last.nil?
      last_dates << stock_last.date if !stock_last.nil?

      [first_dates.min, last_dates.max]
    end

    def self.explode_days min_date, max_date
      (min_date.to_date..max_date.to_date).to_a
    end

    def self.create_data sales, stock
      # from [date, sales] and [date, stock] create realistic list
      from_date, to_date = date_minmax sales, stock
      days = explode_days from_date, to_date
      data = {}
      days.each do |day|
        data[day] = {label: day,
                     stock: stock.find{|s| s.date.to_date == day}.try(:qty) || 0,
                     sales: sales.find{|s| s[0].to_date == day}.try(:fetch, 1) || 0
        }
      end
      data
    end
  end
end
