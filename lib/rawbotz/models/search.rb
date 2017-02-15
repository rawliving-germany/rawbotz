require 'active_model'

module Rawbotz
  module Models
    class Search
      include ActiveModel::Model # convenience
      include RawgentoModels

      attr_accessor :term, :fields, :products, :remote_products

      def perform!
        # Life could be so easy with AR5 #or
        constraints = []
        if [*@fields].include?(:name) || [*@fields].include?(:all)
          constraints << LocalProduct.unscoped.name_ilike(@term).arel.constraints
        end
        if [*@fields].include?(:id) || [*@fields].include?(:all)
          constraints << LocalProduct.unscoped.where(id: @term.to_i).arel.constraints
        end
        if [*@fields].include?(:product_id) || [*@fields].include?(:all)
          constraints << LocalProduct.unscoped.where(product_id: @term.to_i).arel.constraints
        end
        arel = constraints[0]

        id_code = Arel::Nodes::NamedFunction.new(
          "CAST",
          [LocalProduct.arel_table[:id].as("TEXT")]
        )

        product_id_code = Arel::Nodes::NamedFunction.new(
          "CAST",
          [LocalProduct.arel_table[:product_id].as("TEXT")]
        )

        @products = LocalProduct.unscoped.where(
          id_code.matches("%#{@term}%"
          ).or(product_id_code.matches("%#{@term}%")
          ).or(
            LocalProduct.arel_table[:name].matches(
              "%#{@term}%"
            )
          )
        )
        #constraints[1..-1].inject(arel){|a, c| a.or(c)}
        #@products = LocalProduct.where(arel)
      end

      def perform_for_remote!
        # Life could be so easy with AR5 #or
        constraints = []
        if [*@fields].include?(:name) || [*@fields].include?(:all)
          constraints << RemoteProduct.unscoped.name_ilike(@term).arel.constraints
        end
        if [*@fields].include?(:id) || [*@fields].include?(:all)
          constraints << RemoteProduct.unscoped.where(id: @term.to_i).arel.constraints
        end
        if [*@fields].include?(:product_id) || [*@fields].include?(:all)
          constraints << RemoteProduct.unscoped.where(product_id: @term.to_i).arel.constraints
        end
        arel = constraints[0]

        id_code = Arel::Nodes::NamedFunction.new(
          "CAST",
          [RemoteProduct.arel_table[:id].as("TEXT")]
        )

        product_id_code = Arel::Nodes::NamedFunction.new(
          "CAST",
          [RemoteProduct.arel_table[:product_id].as("TEXT")]
        )

        @remote_products = RemoteProduct.unscoped.where(
          id_code.matches("%#{@term}%"
          ).or(product_id_code.matches("%#{@term}%")
          ).or(
            RemoteProduct.arel_table[:name].matches(
              "%#{@term}%"
            )
          )
        )
        #constraints[1..-1].inject(arel){|a, c| a.or(c)}
        #@remote_products = LocalProduct.where(arel)
      end
    end
  end
end
