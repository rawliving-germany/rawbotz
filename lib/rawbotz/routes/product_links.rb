require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::ProductLinks
  include RawgentoModels

  def self.registered(app)

    # app.get  '/products/links',     &show_products_links
    show_products_links = lambda do
      @local_products = LocalProduct.supplied_by(settings.supplier)
      @remote_products = RemoteProduct.supplied_by(settings.supplier)
      haml "products/links".to_sym
    end

    # app.get  '/products/link_wizard', &show_link_wizard
    show_link_wizard = lambda do
      @unlinked_count = settings.supplier.local_products.unlinked.count
      @local_product = settings.supplier.local_products.unlinked.first
      params[:idx] = 0
      haml "products/link_wizard".to_sym
    end

    # app.get  '/products/link_wizard/:idx', &show_link_wizard_id
    show_link_wizard_id = lambda do
      @unlinked_count = LocalProduct.supplied_by(settings.supplier).unlinked.count
      @local_product = LocalProduct.supplied_by(settings.supplier).unlinked.at(params[:idx].to_i || 0)
      haml "products/link_wizard".to_sym
    end

    # app.get  '/product/:id/link',          &link_product_view
    link_product_view = lambda do
      @product = RawgentoModels::LocalProduct.find(params[:id])
      @remote_products = RawgentoModels::RemoteProduct
      haml 'product/link_to'.to_sym
    end

    # app.post '/product/:id/link',          &link_product
    link_product = lambda do
      remote_product = RemoteProduct.find(params[:remote_product_id])
      @product = RawgentoModels::LocalProduct.find(params[:id])
      @product.remote_product = remote_product
      @product.save

      if request.xhr?
        remote_product_link remote_product
      else
        add_flash :success, "Linked Product '#{@product.name}' to '#{@product.remote_product.name}'"

        if params[:redirect_to] == "link_wizard"
          redirect '/products/link_wizard'
        elsif params[:redirect_to] == "links"
          redirect "/products/links"
        elsif params[:redirect_to]
          redirect "/products/links"
        else
          redirect "/product/#{params[:id]}"
        end
      end
    end

    app.get  '/products/links',            &show_products_links
    app.get  '/products/link_wizard',      &show_link_wizard
    app.get  '/products/link_wizard/:idx', &show_link_wizard_id

    app.get  '/product/:id/link',          &link_product_view
    app.post '/product/:id/link',          &link_product
  end
end
