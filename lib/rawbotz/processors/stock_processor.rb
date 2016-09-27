require 'date'

module Rawbotz
  module Processors
    class StockProcessor < Processor
      include RawgentoModels

      attr_accessor :order
      attr_accessor :params
      attr_accessor :magento_shell_path

      def initialize(order, params)
        @success_message = "Order stocked"
        @order  = order
        @params = params
        @magento_shell_path = YAML.load_file(Rawbotz.conf_file_path)["local_shop"]["magento_shell_path"]
        super()
      end

      # Add items to stock, setting them available if they were not before (and
      # stock is positive).
      #
      # Returns and sets @error array which is empty if everything went smooth.
      def process!
        num_stocked = 0

        @params.each do |param_name, param_value|
          if param_name.to_s.start_with?("qty_delivered_") && param_value != ""
            stock! param_name[14..-1], param_value
            num_stocked += 1
          end
        end

        if @order.order_items.processible.ordered.where("num_stocked IS NULL").count == 0
          @order.update(state: 'stocked', stocked_at: DateTime.now)
        else
          # Be more helpful in this error message, like iterate the problematic ones
          @errors << "Not all items stocked"
        end

        if num_stocked > 0 && num_stocked >= @errors.length && !magento_shell_path.nil?
          reindex_status = system("php #{@magento_shell_path} --reindex cataloginventory_stock")
          if reindex_status.nil?
            @errors << "Magento database reindexing failed"
          end
        end

        @errors
      end

      private

      def stock! order_item_id, qty
        order_item = @order.order_items.find(order_item_id)
        # This should be logged
        return if order_item.blank? || order_item.stocked?

        begin
          RawgentoDB::Query.update_stock order_item.local_product.product_id, qty.to_i
          RawgentoDB::Query.set_available_on_stock order_item.local_product.product_id
          # Would be good to log that
          order_item.update(num_stocked: qty.to_i, state: :stocked)
          order_item.save
        rescue Exception => e
          STDERR.puts e.message.to_s
          STDERR.puts e.backtrace
          @errors << e.message
        end
      end

      end
    end
  end
end
