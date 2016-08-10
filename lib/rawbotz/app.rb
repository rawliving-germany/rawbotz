require 'sinatra/base'
require 'open-uri'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'
require 'rawbotz/helpers/icon_helper'
require 'rawbotz/helpers/flash_helper'
require 'rawbotz/helpers/resource_link_helper'
require 'rawbotz/helpers/order_item_color_helper'
require 'tilt/haml'

class RawbotzApp < Sinatra::Base
  include RawgentoModels

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
  end

  helpers do ; end
  helpers Rawbotz::Helpers::IconHelper
  helpers Rawbotz::Helpers::FlashHelper
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
  register Rawbotz::RawbotzApp::Routing::ProductLinks

  # get '/remote_cart'
  # get '/remote_orders'
  # get '/remote_order/:id'
  register Rawbotz::RawbotzApp::Routing::RemoteShop

  # get  '/supplier/:id'
  # post '/supplier/:id'
  register Rawbotz::RawbotzApp::Routing::Suppliers

  # get  '/orders/non_remote'
  # get  '/order/non_remote/:order_id'
  # post '/order/non_remote/:order_id'
  # get  '/order/non_remote/:supplier_id/new'
  register Rawbotz::RawbotzApp::Routing::NonRemoteOrders

  get '/maintenance' do
    haml :maintenance
  end
end
