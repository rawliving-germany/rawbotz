require 'sinatra/base'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'

require 'rawgento_models'
require 'rawgento_db'

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
