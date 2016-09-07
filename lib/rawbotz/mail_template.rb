module Rawbotz
  module MailTemplate
    def self.create order
      mail_adresses = split_mail_field order.supplier[:email]
      Rawbotz::Models::OrderMail.new(to: mail_adresses[0],
                    cc: mail_adresses[1..-1],
                    subject: extract_subject(order.supplier[:order_template], order),
                    body: consume(order.supplier[:order_template], order)
                   )
    end

    # Substitute certain patterns in template
    def self.consume template, order
      result = ""
      result = template.gsub(/SUPPLIERNAME/, order.supplier[:name])
      result = result.gsub(/PUBLIC_COMMENT/, order.public_comment || "")

      lines = result.split("\n")
      subject, lines = lines.partition{|l| l.start_with?("SUBJECT=")}
      product_line = lines.detect{|l| l.start_with?("* ")}
      order_lines = order.order_items.select{|o|o.num_wished.to_i != 0}.map do |oi|
        next if product_line.nil?
        order_item_line = product_line[2..-1]
        order_item_line.gsub!(/SUPPLIERSKU/, oi.local_product[:supplier_sku].to_s)
        order_item_line.gsub!(/QTY/, oi[:num_wished].to_s)
        if oi.local_product[:packsize].to_s != ""
          order_item_line.gsub!(/NUM_PACKS/, "%g" % (oi[:num_wished] / oi.local_product[:packsize].to_f))
        else
          order_item_line.gsub!(/NUM_PACKS/, '')
        end
        order_item_line.gsub!(/PACKSIZE/, oi.local_product[:packsize].to_s)
        if oi.local_product[:supplier_prod_name].to_s != ""
          order_item_line.gsub!(/PRODUCTNAME/, oi.local_product[:supplier_prod_name])
        else
          order_item_line.gsub!(/PRODUCTNAME/, oi.local_product[:name].to_s)
        end
        order_item_line
        #SUPPLIERSKU
        #SUPPLIERPRODUCTNAME
      end
      lines[lines.find_index(product_line)] = order_lines if product_line
      lines.flatten.join("\n")
    end

    def self.extract_subject template, order
      result = ""
      result = template.gsub(/SUPPLIERNAME/, order.supplier[:name])

      lines = result.split("\n")
      subject, lines = lines.partition{|l| l.start_with?("SUBJECT=")}
      if !subject.empty?
        subject[0][8..-1]
      else
        "Order"
      end
    end

    def self.split_mail_field adresses_text
      adresses = (adresses_text.to_s || "").split
    end

    def self.create_mailto_url supplier, order
      mail_preview = self.consume supplier[:order_template], order
      subject = self.extract_subject supplier[:order_template], order
      to_mail = (supplier[:email] || "").split[0]
      if supplier[:email].to_s == ""
        cc_mail = ""
      else
        cc_mail = supplier[:email].split[1..-1].map{|m| "cc=#{m}"}.join("&")
      end
      if cc_mail.to_s != ""
        cc_mail += "&"
      end
      "mailto:#{to_mail}?#{cc_mail}Subject=#{subject}&body=%s" % URI::escape(mail_preview).gsub(/&/,'%26')
    end
  end
end
