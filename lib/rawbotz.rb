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
end
