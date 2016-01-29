require "rawbotz/version"

require 'rawgento_models'
require 'rawgento_db'

# require app yourself!

module Rawbotz
  @@conf_file_path = nil
  def self.conf_file_path=(conf_file_path)
    @@conf_file_path = conf_file_path
  end
  def self.conf_file_path
    @@conf_file_path
  end

  # Configure components (from config file path), exit 1 if fails.
  # 'logs' to STDERR (TODO)
  def self.configure!
    begin
      RawgentoModels.establish_connection @@conf_file_path
    rescue
      STDERR.puts "Could not establish rawbotz-database connection (read config from: #{@@conf_file_path})"
      exit 1
    end
    begin
      RawgentoDB.settings @@conf_file_path
    rescue
      STDERR.puts "Could not establish magento-database connection (read config from: #{@@conf_file_path})"
      exit 1
    end
    # As a bonus, set mechs config (TODO)
  end
end
