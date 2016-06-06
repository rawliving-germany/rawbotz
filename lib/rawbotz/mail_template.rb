module Rawbotz
  module MailTemplate
    # Substitute certain patterns in template
    def self.consume template, order
      result = ""
      result = template.gsub(/SUPPLIERNAME/, order[:supplier][:name])

      lines = result.split("\n")
      subject, lines = lines.partition{|l| l.start_with?("SUBJECT=")}
      product_line = lines.detect{|l| l.start_with?("* ")}
      order_lines = order[:order_items].map do |oi|
        next if product_line.nil?
        order_item_line = product_line[2..-1]
        order_item_line.gsub!(/PRODUCTCODE/, '')
        order_item_line.gsub!(/QTY/, oi[:num_wished].to_s)
        if oi[:local_product][:packsize].to_s != ""
          order_item_line.gsub!(/NUM_PACKS/, (oi[:num_wished] / oi[:local_product][:packsize].to_f).to_s)
        else
          order_item_line.gsub!(/NUM_PACKS/, '')
        end
        order_item_line.gsub!(/PACKSIZE/, oi[:local_product][:packsize].to_s)
        order_item_line.gsub!(/PRODUCTNAME/, oi[:local_product][:name].to_s)
        order_item_line
      end
      lines[lines.find_index(product_line)] = order_lines
      lines.flatten.join("\n")
    end
  end
end
