require "rawbotz/version"
require "rawbotz/remote_shop"

require 'rawgento_models'
require 'rawgento_db'

require 'ostruct'

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

  def self.new_mech
    config_values = YAML::load_file(@@conf_file_path)["remote_shop"]
    MagentoMech.from_config OpenStruct.new(config_values)
  end
end
