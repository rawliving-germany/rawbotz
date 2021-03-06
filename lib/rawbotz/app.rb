require 'sinatra/base'
require 'open-uri'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'active_support'

require 'haml'
require 'rawbotz/helpers/flash_helper'
require 'rawbotz/helpers/format_helper'
require 'rawbotz/helpers/icon_helper'
require 'rawbotz/helpers/js_helper'
require 'rawbotz/helpers/resource_link_helper'
require 'rawbotz/helpers/order_item_color_helper'
require 'tilt/haml'

require 'bcrypt'

class RawbotzApp < Sinatra::Base
  include RawgentoModels
  include ActionView::Helpers::TextHelper

  enable :sessions

  configure do
    # Setup local rawbotz database
    if Rawbotz.conf_file_path
      RawgentoModels.establish_connection Rawbotz.conf_file_path
    else
      RawgentoModels.establish_connection
    end

    # Configure local mysql database
    RawgentoDB.settings(Rawbotz.conf_file_path)

    # And RemoteShop
    conf = YAML.load_file(Rawbotz.conf_file_path)
    set :supplier_name, conf["supplier_name"]
    set :supplier, Supplier.find_by(name:
                                    conf["supplier_name"])
    set :conf, conf

    if conf["authentication"] && !conf["authentication"].empty?
      use Rack::Auth::Basic, "Protected Area, no robots allowed" do |username, password|
        if username.nil? || password.nil? || conf["authentication"][username].nil?
          nil
        else
          BCrypt::Password.new(conf["authentication"][username]) == password
        end
      end
    end
  end

  helpers do ; end
  helpers Rawbotz::Helpers::FlashHelper
  helpers Rawbotz::Helpers::FormatHelper
  helpers Rawbotz::Helpers::IconHelper
  helpers Rawbotz::Helpers::JSHelper
  helpers Rawbotz::Helpers::ResourceLinkHelper
  helpers Rawbotz::Helpers::OrderItemColorHelper

  get '/' do
    haml :index
  end

  # routes:
  # get  '/orders'
  # get  '/order/new'
  # get  '/order/:id'
  # post '/order/:id/'
  # get  '/order/:id/packlist'
  # get  '/order/:id/packlist/pdf'
  register Rawbotz::RawbotzApp::Routing::Orders

  # get  '/order/:id/stock
  # post '/order/:id/stock'
  # get  '/order/:id/link_to_remote'
  # post '/order/:id/link_to_remote'
  register Rawbotz::RawbotzApp::Routing::Orders::Stock

  # get  '/products'
  # post '/products/search'
  # get  '/product/:id'
  # get  '/product/:id/stock_sales_plot'
  # post '/product/:id/hide'
  # post '/product/:id/unhide'
  # get  '/remote_products'
  # post '/remote_products/search'
  # get  '/remote_product/:id'
  register Rawbotz::RawbotzApp::Routing::Products

  # get  '/products/links'
  # get  '/products/link_wizard'
  # get  '/products/link_wizard/:idx'
  # get  '/product/:id/link'
  # post '/product/:id/link'
  # get  '/product/:id/unlink'
  register Rawbotz::RawbotzApp::Routing::ProductLinks

  # get '/remote_cart'
  # get '/remote_orders'
  # get '/remote_order/:id'
  register Rawbotz::RawbotzApp::Routing::RemoteShop

  # get  '/supplier/:id'
  # post '/supplier/:id'
  register Rawbotz::RawbotzApp::Routing::Suppliers

  # get '/supplier/:id/organic_deliveries'
  # get '/supplier/:id/organic_deliveries.csv'
  register Rawbotz::RawbotzApp::Routing::Suppliers::Orders

  # app.post '/search/products', &search_products
  register Rawbotz::RawbotzApp::Routing::Search

  # get '/stock'
  # get '/stock/alerts'
  # get '/stock/warnings'
  register Rawbotz::RawbotzApp::Routing::Stock

  # get  '/orders/non_remote'
  # get  '/order/non_remote/:order_id'
  # post '/order/non_remote/:order_id'
  # get  '/order/non_remote/:supplier_id/new'
  register Rawbotz::RawbotzApp::Routing::NonRemoteOrders

  get '/maintenance' do
    haml :maintenance
  end
end
