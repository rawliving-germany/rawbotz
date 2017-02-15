require 'rawbotz/routes'

module Rawbotz::RawbotzApp::Routing::Search
  include Rawbotz
  include RawgentoModels

  def self.registered(app)
    # app.post '/search/products', &search_products
    search_products = lambda do
      @term = params[:term]
      if request.xhr?
        @products = LocalProduct.name_ilike(@term).limit(20)
          .pluck(:name, :id)
        # TODO issue #43 add remote products,too
        @products.map{|p| {name: p[0], product_id: p[1]}}.to_json
      else
        search = Models::Search.new(term: @term, fields: :all)
        @products = search.perform!
        @remote_products = search.perform_for_remote!
        haml "search/product_search_results".to_sym
      end
    end

    app.post '/search/products', &search_products
  end
end
