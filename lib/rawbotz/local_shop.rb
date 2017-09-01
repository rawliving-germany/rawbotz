module Rawbotz
  module LocalShop
    def self.product_page_frontend(product, settings)
      # TODO settings could be memoized
      "#{settings['local_shop']['base_uri']}catalog/product/view/id/#{product.product_id}"
    end
    def self.product_page_backend(product, settings)
      # TODO settings could be memoized
      "#{settings['local_shop']['base_uri']}rawadmin/catalog/product/edit/id/#{product.product_id}"
    end
  end
end
