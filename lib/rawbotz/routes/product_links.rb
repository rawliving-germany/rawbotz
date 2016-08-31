require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::ProductLinks
  include RawgentoModels

  def self.registered(app)

    # app.get  '/products/links',     &show_products_links
    show_products_links = lambda do
      @local_products  = LocalProduct.supplied_by(settings.supplier)
      @remote_products = RemoteProduct.supplied_by(settings.supplier)
      @weird_products  = RemoteProduct.where.not(local_product_id: nil).joins(:local_product).where.not(local_products: {supplier_id: 1})
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

    # app.get  '/product/:id/unlink',        &unlink_product
    unlink_product = lambda do
      @product = RawgentoModels::LocalProduct.find(params[:id])
      @product.remote_product.update(local_product: nil)
      add_flash :success, "Unlinked #{@product.name}"
      redirect '/products/links'
    end

    # app.post '/product/:id/link',          &link_product
    link_product = lambda do
      remote_product = RemoteProduct.find_by(id: params[:remote_product_id])

      if remote_product.present?
        @product = RawgentoModels::LocalProduct.find(params[:id])
        if remote_product.local_product.present?
          add_flash :info, "Changing link of '#{remote_product.name}', was: #{remote_product.local_product.name}"
        end
        @product.remote_product = remote_product
        @product.save
        add_flash :success, "Linked Product '#{@product.name}' to '#{@product.remote_product.name}'"
      else
        add_flash :error, "Could not set link for '#{@product.name}'."
      end

      if request.xhr?
        remote_product_link remote_product
      else

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

    # routes
    app.get  '/products/links',            &show_products_links
    app.get  '/products/link_wizard',      &show_link_wizard
    app.get  '/products/link_wizard/:idx', &show_link_wizard_id

    app.get  '/product/:id/link',          &link_product_view
    app.post '/product/:id/link',          &link_product
    app.get  '/product/:id/unlink',        &unlink_product
  end
end
