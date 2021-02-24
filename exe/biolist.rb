#!/usr/bin/env ruby

require 'date'

require "rawbotz"
require "rawbotz/option_parser"

optparse = Rawbotz::OptionParser.new do |opts, options|
  opts.banner = "Usage: #{$PROGRAM_NAME} [OPTIONS]"
  opts.separator ""
end
optparse.parse!
options = optparse.options

include RawgentoModels

def main options
  logger = Logger.new(STDOUT)
  logger.level = options[:verbose] ? Logger::DEBUG : Logger::INFO

  logger.debug "#{$PROGRAM_NAME} #{Rawbotz::VERSION}"

  #RawgentoModels.establish_connection# options[:config]

  csv_data = [["product_id", "product_name", "name_attr", "organic?", "sales", "eknetto", "cost", "stock 31.03.2020", "activated"]]


  begin
    stocks = {}
    RawgentoDB::Query.stock.each do |s|
      stocks[s.product_id] = s.qty
    end

    costs = {}
    RawgentoDB::Query::attribute_decimal(100).each do |product_id, value|
      costs[product_id] = value
    end

    eknettos = {}
    RawgentoDB::Query::attribute_varchar(1042).each do |product_id, value|
      eknettos[product_id] = value
    end

    names = {}
    RawgentoDB::Query::attribute_varchar(Rawbotz.attribute_ids["name"]).each do |product_id, value|
      names[product_id] = value
    end

    other_names = {}
    RawgentoDB::Query::attribute_varchar(96).each do |product_id, value|
      other_names[product_id] = value
    end

    activated = {}
    RawgentoDB::Query::attribute_int(273).each do |product_id, value|
      activated[product_id] = value
    end

    RawgentoModels::LocalProduct.unscoped.find_each do |local_product|
      puts local_product.product_id

      sales_monthly = RawgentoDB::Query.sales_monthly_between(
        local_product.product_id, DateTime.civil(2019,9,1,0,0), DateTime.civil(2020,3,31,23,59)
      )

      csv_data << [local_product.product_id, names[local_product.product_id], other_names[local_product.product_id],#local_product.name,
        local_product.organic?, sales_monthly.inject(0) {|acc, s| acc + s[1].to_i },
        eknettos[local_product.product_id],
        costs[local_product.product_id],
        stocks[local_product.product_id],
        activated[local_product.product_id]
      ]

    end

    CSV.open("/tmp/organic_sales.csv", "wb") do |csv|
      csv_data.each do |data|
        csv << data
      end
    end

  rescue Mysql2::Error => e
    logger.error "Problems accessing MySQL database #{e.inspect}"
    exit 2
  end

  now = DateTime.now

end

main options

exit 0
