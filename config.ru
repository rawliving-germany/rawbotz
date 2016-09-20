# encoding: UTF-8
require 'rawbotz'

if ENV['RAWBOTZ_CONFIG']
  Rawbotz.conf_file_path = ENV['RAWBOTZ_CONFIG']
end

# TODO make this an option
# PDFKit middleware allows to attach '.pdf' to all requests (and get a
# pdf rendered)
#require 'pdfkit'
#use PDFKit::Middleware

require 'rawbotz/app'
run RawbotzApp
