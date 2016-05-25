require "rawbotz/version"
require "rawbotz/remote_shop"
require "rawbotz/local_shop"
require "rawbotz/order_processor"

require 'rawgento_models'
require 'rawgento_db'

require 'ostruct'
require 'yaml'
require 'pony'

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

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  def self.logger= logger
    @logger = logger
  end
  def self.configure_logger options
    logger.level = options[:verbose] ? Logger::DEBUG : Logger::INFO
  end

  def self.new_mech
    config_values = YAML::load_file(@@conf_file_path)["remote_shop"]
    MagentoMech.from_config OpenStruct.new(config_values)
  end

  def self.mail subject, body
    # From config, this should be memoized
    settings = YAML::load_file(Rawbotz::conf_file_path)["mail"]
    pony_via_options = { address: settings["host"],
                         user_name: settings["user"],
                         port: settings["port"].to_i,
                         authentication: :login,
                         password: settings["pass"]}

    Pony.mail({
      to: settings["to"],
      from: settings["from"],
      subject: subject,
      body: body,
      via: :smtp,
      via_options: pony_via_options
    })
  end
end
