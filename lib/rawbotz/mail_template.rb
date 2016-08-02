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
        order_item_line.gsub!(/SUPPLIERSKU/, oi[:local_product][:supplier_sku].to_s)
        order_item_line.gsub!(/QTY/, oi[:num_wished].to_s)
        if oi[:local_product][:packsize].to_s != ""
          order_item_line.gsub!(/NUM_PACKS/, "%g" % (oi[:num_wished] / oi[:local_product][:packsize].to_f))
        else
          order_item_line.gsub!(/NUM_PACKS/, '')
        end
        order_item_line.gsub!(/PACKSIZE/, oi[:local_product][:packsize].to_s)
        if oi[:local_product][:supplier_prod_name].to_s != ""
          order_item_line.gsub!(/PRODUCTNAME/, oi[:local_product][:supplier_prod_name])
        else
          order_item_line.gsub!(/PRODUCTNAME/, oi[:local_product][:name].to_s)
        end
        order_item_line
      end
      lines[lines.find_index(product_line)] = order_lines if product_line
      lines.flatten.join("\n")
    end

    def self.extract_subject template, order
      result = ""
      result = template.gsub(/SUPPLIERNAME/, order[:supplier][:name])

      lines = result.split("\n")
      subject, lines = lines.partition{|l| l.start_with?("SUBJECT=")}
      if !subject.empty?
        subject[0][8..-1]
      else
        "Order"
      end
    end


    def self.create_mailto_url supplier, order
      mail_preview = self.consume supplier[:order_template], order
      subject = self.extract_subject supplier[:order_template], order
      "mailto:#{supplier[:email]}?Subject=#{subject}&body=%s" % URI::escape(mail_preview).gsub(/&/,'%26')
    end
  end
end
