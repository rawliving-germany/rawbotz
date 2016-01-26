require 'sinatra/base'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'

class RawbotzApp < Sinatra::Base
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
    set :supplier, YAML.load_file(Rawbotz.conf_file_path)["supplier_name"]
  end

  helpers do
    def local_product_link product
      "<a href=\"/product/#{product.id}\">#{product.name}</a>"
    end
    def remote_product_link product
      "<a href=\"/remote_product/#{product.id}\">#{product.name}</a>"
    end
  end

  get '/' do
    haml :index
  end

  get '/products' do
    @products = RawgentoModels::LocalProduct
    @suppliers = RawgentoModels::LocalProduct.uniq.pluck(:supplier)
    haml "products/index".to_sym
  end

  get '/products/links' do
    @local_products = RawgentoModels::LocalProduct#.supplied_by()
    @remote_products = RawgentoModels::RemoteProduct#.supplied_by()
    haml "products/links".to_sym
  end

  get '/remote_products' do
    @products = RawgentoModels::RemoteProduct.all
    haml "remote_products/index".to_sym
  end

  get '/product/:id/link' do
    @product = RawgentoModels::LocalProduct.find(params[:id])
    # filter by supplier ...
    @remote_products = RawgentoModels::RemoteProduct
    haml 'product/link_to'.to_sym
  end

  post '/product/:id/link' do
    remote_product = RawgentoModels::RemoteProduct.find(params[:remote_product_id])
    @product = RawgentoModels::LocalProduct.find(params[:id])
    @product.remote_product = remote_product
    @product.save
    redirect "/product/#{params[:id]}"
  end

  get '/product/:id' do
    @product = RawgentoModels::LocalProduct.find(params[:id])
    #@sales = RawgentoDB::Query.sales(@product.product_id, RawgentoDB.settings)
    @sales = []
    haml "product/view".to_sym
  end

  get '/maintenance' do
    haml :maintenance
  end
end
