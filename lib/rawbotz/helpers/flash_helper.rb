module Rawbotz
  module Helpers
    module FlashHelper
      def flash
        @flash = session[:flash]# || {}
      end
      def add_flash kind, *messages
        messages.each do |msg|
          session[:flash] ||= {}
          (session[:flash][kind] ||= []) << msg
        end
      end
    end
  end
end
