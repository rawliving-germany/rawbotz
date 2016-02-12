require 'sinatra/base'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'

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
    set :supplier, YAML.load_file(Rawbotz.conf_file_path)["supplier_name"]
  end

  helpers do
    def local_product_link product
      "<a href=\"/product/#{product.id}\">#{product.name}</a>"
    end
    def remote_product_link product
      "<a href=\"/remote_product/#{product.id}\">#{product.name}</a>"
    end
    def flash
      @flash = session[:flash]# || {}
    end
    def add_flash kind, msg
      session[:flash] ||= {}
      (session[:flash][kind] ||= []) << msg
    end
  end

  get '/' do
    haml :index
  end

  get '/products' do
    @products = LocalProduct
    @suppliers = LocalProduct.uniq.pluck(:supplier)
    haml "products/index".to_sym
  end

  get '/products/links' do
    @local_products = LocalProduct.supplied_by(settings.supplier)
    @remote_products = RemoteProduct.supplied_by(settings.supplier)
    haml "products/links".to_sym
  end

  get '/products/link_wizard' do
    @unlinked_count = LocalProduct.unlinked.count
    @local_product = LocalProduct.supplied_by(settings.supplier).unlinked.at(0)
    params[:idx] = 0
    haml "products/link_wizard".to_sym
  end

  get '/products/link_wizard/:idx' do
    @unlinked_count = LocalProduct.unlinked.count
    @local_product = LocalProduct.supplied_by(settings.supplier).unlinked.at(params[:idx].to_i || 0)
    haml "products/link_wizard".to_sym
  end

  post '/remote_products/search' do
    @products = RemoteProduct.supplied_by(settings.supplier)
      .where('lower(name) LIKE ?', "%#{params[:term].downcase}%").limit(10).pluck(:name, :id)
    @products.map{|p| {name: p[0], product_id: p[1]}}.to_json
  end

  get '/orders' do
    @orders = Order.all
    haml "orders/index".to_sym
  end

  get '/order/new' do
    @order = Order.create(state: :new)

    # Restrict to supplier
    understocked = RawgentoDB::Query.understocked
    understocked.each do |product_id, name, min_qty, in_stock|
      local_product = LocalProduct.find_by(product_id: product_id)
      @order.order_items.create(local_product: local_product, current_stock: in_stock, min_stock: min_qty)
    end
    haml "order/new".to_sym
  end

  get '/order/:id' do
    @order = Order.find(params[:id])
    haml "order/view".to_sym
  end

  get '/remote_orders' do
    #@products = RawgentoModels::RemoteProduct.all
    @last_orders =  []
    @last_orders = Rawbotz.mech.last_orders
    haml "remote_orders/index".to_sym
  end

  get '/remote_order/:id' do
    #@products = RawgentoModels::RemoteProduct.all
    @remote_order_items = Rawbotz.mech.products_from_order params[:id]
    @remote_products_qty = @remote_order_items.map do |remote_product|
      [RawgentoModels::RemoteProduct.find_by(name: remote_product[0]), remote_product[2]]
    end
    haml "remote_order/view".to_sym
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
