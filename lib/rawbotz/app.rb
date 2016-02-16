require 'sinatra/base'
require 'action_view' # Workaround https://github.com/haml/haml/issues/695
require 'haml'
require 'rawbotz/icon_helper'

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

  helpers do
    def local_product_link product
      if product.present?
        "<a href=\"/product/#{product.id}\">#{product.name}</a>"
      else
        "Product not in database"
      end
    end
    def remote_product_link product
      if product.is_a? LocalProduct
        remote_product_link product.remote_product
      elsif product.try(:id)
        "<a href=\"/remote_product/#{product.id}\">"\
        "<i class=\"fa fa-globe\"></i>#{product.name}</a>"
      elsif product.name
        # Used in RemoteOrder view.
        "#{product.name}"
      else
        "not linked"
      end
    end
    def product_link product
      return local_product_link(product) if product.is_a?(LocalProduct)
      return remote_product_link(product) if product.is_a?(RemoteProduct)
      "no product"
    end
    def flash
      @flash = session[:flash]# || {}
    end
    def add_flash kind, msg
      session[:flash] ||= {}
      (session[:flash][kind] ||= []) << msg
    end
  end
  helpers Rawbotz::IconHelper

  get '/' do
    haml :index
  end

  get '/products' do
    @products = LocalProduct
    @suppliers = Supplier.all
    haml "products/index".to_sym
  end

  get '/products/links' do
    @local_products = LocalProduct.supplied_by(settings.supplier)
    @remote_products = RemoteProduct.supplied_by(settings.supplier)
    haml "products/links".to_sym
  end

  get '/products/link_wizard' do
    @unlinked_count = settings.supplier.local_products.unlinked.count
    @local_product = settings.supplier.local_products.unlinked.first
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
      .where('lower(name) LIKE ?', "%#{params[:term].downcase}%").limit(20).pluck(:name, :id)
    @products.map{|p| {name: p[0], product_id: p[1]}}.to_json
  end

  post '/products/search' do
    @products = LocalProduct
      .where('lower(name) LIKE ?', "%#{params[:term].downcase}%").limit(20).pluck(:name, :id)
    @products.map{|p| {name: p[0], product_id: p[1]}}.to_json
  end

  get '/orders' do
    @orders = Order.all.order(created_at: :desc)
    haml "orders/index".to_sym
  end

  get '/orders/non_remote' do
    haml "orders/non_remotes".to_sym
  end

  get '/order/non_remote/:supplier_id' do
    @supplier = Supplier.find(params[:supplier_id])
    # This did not work as "Order" without persistence
    @products = LocalProduct.supplied_by(@supplier)

    #understocked = RawgentoDB::Query.understocked
    #understocked.each do |product_id, name, min_qty, in_stock|
    #  local_product = LocalProduct.find_by(product_id: product_id)
    #    if local_product.supplier == @supplier
    #      @order.build_order_item(local_product: local_product, current_stock: in_stock, min_stock: min_qty)
    #    else
    #      puts "not Dr Georg"
    #    end
    #  end
    #end

    haml "order/non_remote".to_sym
  end

  post '/order/non_remote/:supplier_id' do
    supplier = Supplier.find(params.delete("supplier_id"))
    # Some of these mails might want to be templated

    mail_body = "Dear #{supplier.name}\n\n"
    params.select{|p| p.start_with?("item_")}.each do |p, val|
      if val && val.to_i > 0
        qty = val.to_i
        product = LocalProduct.find(p[5..-1])
        mail_body << "#{product.name}: #{qty}"
        if product.packsize
          mail_body << " (#{(qty/product.packsize)} Gebinde)"
        end
        mail_body << "\n"
      end
    end

    mail_body << "Mit freundlichen Grüßen ...\nZu senden an...\n"
    mail_subject = "Bestellung an #{supplier.name}"

    Rawbotz::mail(mail_subject, mail_body)

    add_flash :success, "Order details send via mail"
    redirect "/"
  end

  get '/order/new' do
    if !Order.current.present?
      @order = Order.create(state: :new)

      # Restrict to supplier
      understocked = RawgentoDB::Query.understocked
      understocked.each do |product_id, name, min_qty, in_stock|
        local_product = LocalProduct.find_by(product_id: product_id)
        if local_product.supplier == settings.supplier
          @order.order_items.create(local_product: local_product, current_stock: in_stock, min_stock: min_qty)
        end
      end
      add_flash :success, "New Order created"
    else
      add_flash :message, "Already one Order in progress"
      @order = Order.current
    end
    redirect "/order/#{@order.id}"
    #haml "order/new".to_sym
  end

  get '/order/:id' do
    @order = Order.find(params[:id])
    haml "order/view".to_sym
  end

  post '/order/:id' do
    @order = Order.find(params[:id])
    params.each do |k,v|
      if k && k.start_with?("item_") && v != ""
        OrderItem.find(k[5..-1]).update(num_wished: v.to_i)
      end
    end
    if params['action'] == 'order'
      @order.update(state: :queued)
      add_flash :success, 'Order queued'
      redirect '/orders'
    elsif params['action'] == 'delete'
      @order.update(state: :deleted)
      add_flash :success, 'Order marked deleted'
      redirect '/orders'
    else
      haml "order/view".to_sym
    end
  end

  get '/remote_cart' do
    @cart_content = Rawbotz.mech.get_cart_content
    @cart_products = @cart_content.map do |name, qty|
      [RemoteProduct.find_by(name: name), qty]
    end
    haml "remote_cart/index".to_sym
  end

  get '/remote_orders' do
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

  get '/remote_product/:id' do
    @product = RawgentoModels::RemoteProduct.find(params[:id])
    haml "remote_product/view".to_sym
  end

  get '/product/:id/link' do
    @product = RawgentoModels::LocalProduct.find(params[:id])
    # filter by supplier ...
    @remote_products = RawgentoModels::RemoteProduct
    haml 'product/link_to'.to_sym
  end

  post '/product/:id/link' do
    remote_product = RemoteProduct.find(params[:remote_product_id])
    @product = RawgentoModels::LocalProduct.find(params[:id])
    @product.remote_product = remote_product
    @product.save

    if request.xhr?
      # return product link
      remote_product_link remote_product
    else
      add_flash :success, "Linked Product '#{@product.name}' to '#{@product.remote_product.name}'"

      if params[:redirect_to] == "link_wizard"
        redirect '/products/link_wizard'
      elsif params[:redirect_to] == "links"
        redirect "/product/#{params[:id]}"
      elsif params[:redirect_to]
        redirect "/products/links"
      else
        redirect "/product/#{params[:id]}"
      end
    end
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
