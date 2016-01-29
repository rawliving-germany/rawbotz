require 'optparse'

module Rawbotz
  class OptionParser < ::OptionParser
    attr_accessor :options

    def initialize(*args)
      @options = {}
      super *args
      default_options!
      yield(self, @options) if block_given?
    end

    private

    def default_options!
      separator "Output Options"
      on("-v", "--[no-]verbose", 'Run verbosely') do |c|
        @options[:verbose] = c
      end
      separator "Configuration file"
      on("-c", "--config FILE", 'File path to YAML config file.') do |c|
        Rawbotz.conf_file_path = c
        Rawbotz.configure!
      end
      separator "General"
      on_tail('--version', 'Show version and exit.') do
        puts "part of rawbotz #{Rawbotz::VERSION}"
        exit 0
      end
      on('-h', '--help', 'Show this help and exit.') do
        puts self
        exit 0
      end
    end
  end
end
