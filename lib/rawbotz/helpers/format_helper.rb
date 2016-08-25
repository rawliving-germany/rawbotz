module Rawbotz
  module Helpers
    module FormatHelper
      # makes 1.7923 -> 1.79
      # 200.00 -> 200
      def friendly_float value
        if value.nil?
          return nil
        end
        "%g" % ("%.2f" % value )
      end
    end
  end
end
