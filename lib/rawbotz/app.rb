require 'sinatra/base'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'

class RawbotzApp < Sinatra::Base
  configure do
    if Rawbotz.conf_file_path
      RawgentoModels.establish_connection Rawbotz.conf_file_path
    else
      RawgentoModels.establish_connection
    end
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
    @products = RawgentoModels::LocalProduct.all
    haml "products/index".to_sym
  end

  get '/products/links' do
    @local_products = RawgentoModels::LocalProduct.supplied_by()
    @remote_products = RawgentoModels::RemoteProduct.supplied_by()
    haml "products/links".to_sym
  end

  get '/product/:id/link' do
    @product = RawgentoModels::LocalProduct.find(params[:id])
    # filter by supplier ...
    @remote_products = RawgentoModels::RemoteProduct.all
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
