module Rawbotz
  class ChartMonthDataset
    attr_accessor :date, :value, :length, :darkness
    def initialize date, value, length, darkness
      @date   = date
      @value  = value
      @length = length
      @darkness = darkness
    end

    def to_s
      monthname = Date::MONTHNAMES[@date.month]
      <<-eos
      {
      label: "Sales #{monthname[0..2]} #{@date.year}",
      fill: true,
      lineTension: 0.2,
      backgroundColor: "rgba(175,155,155,0)",
      borderColor: "rgba(35,42,102,#{@darkness})",
      borderCapStyle: 'round',
      pointBorderColor: "rgba(0,0,0,#{@darkness})",
      pointBackgroundColor: "#fff",
      pointBorderWidth: 1,
      pointHoverRadius: 8,
      pointHoverBackgroundColor: "rgba(99,102,152,1)",
      pointHoverBorderColor: "rgba(210,210,210,1)",
      pointHoverBorderWidth: 2,
      pointRadius: 2,
      pointHitRadius: 10,
      data : [#{([@value] * @length).join(',')}]
      },
      eos
      #/*data : [#{plot_data.values.map{|v| v[:stock].to_i}.join(',')}]*/
    end
  end
end
