require 'sinatra/base'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'

class RawbotzApp < Sinatra::Base
  configure :development do
    RawgentoModels.establish_connection
  end

  get '/' do
    haml :index
  end

  get '/products' do
    @products = RawgentoModels::LocalProduct.all
    haml "products/index".to_sym
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
