module Rawbotz
  module Processors
    class Processor
      attr_accessor :outcome
      attr_accessor :errors
      attr_accessor :success_message

      def initialize
        @errors = []
      end

      def succeeded?
        @errors.empty?
      end

      def failed?
        !succeeded?
      end

      def messages
        succeeded? ? [@success_message] : @errors
      end
    end
  end
end
