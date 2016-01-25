# encoding: UTF-8
require 'rawbotz'

if ENV['RAWBOTZ_CONFIG']
  Rawbotz.conf_file_path = ENV['RAWBOTZ_CONFIG']
end

require 'rawbotz/app'
run RawbotzApp
