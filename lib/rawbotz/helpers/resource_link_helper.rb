module Rawbotz
  module Helpers
    module ResourceLinkHelper
      include RawgentoModels

      def local_product_link product
        if product.present?
          if product.name.empty?
            "<a href=\"/product/#{product.id}\">[no product name!]</a>"
          else
            "<a href=\"/product/#{product.id}\">#{product.name}</a>"
          end
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
      def supplier_link supplier
        if supplier.to_s != ""
          "<a href=\"/supplier/#{supplier.id}\">#{supplier.name}</a>"
        else
          "[no supplier]"
        end
      end
    end
  end
end

