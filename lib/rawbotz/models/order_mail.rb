require 'active_model'

module Rawbotz
  module Models
    class OrderMail
      include ActiveModel::Model # convenience

      attr_accessor :subject
      attr_accessor :body
      attr_accessor :to
      attr_accessor :cc

      def mailto_url
        if cc.present?
          cc_mail = cc.map{|m| "cc=#{m}"}.join("&") + "&"
        else
          cc_mail = ""
        end

        "mailto:#{@to}?#{cc_mail}"\
          "Subject=#{@subject}&"\
          "body=%s" %
            URI::escape(@body).gsub(/&/,'%26')
      end
    end
  end
end
