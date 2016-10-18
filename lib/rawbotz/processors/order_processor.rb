require 'date'

module Rawbotz
  module Processors
    class OrderProcessor < Processor

      attr_accessor :order, :logger, :form_token

      def initialize(order, logger=Logger.new("/dev/null"))
        @success_message = "Order ordered"
        @order  = order
        @logger = logger
        @form_token = YAML::load_file(
          Rawbotz::conf_file_path)["remote_shop"]["form_token"]
        super()
      end

      # Yield items, if block given
      def process!
        mech = Rawbotz::new_mech
        mech.login

        @order.order_items.processible.find_each do |item|
          if item.remote_product_id.present? && item.num_wished.present?
            log_product_handling item

            begin
              ordered_qty = mech.add_to_cart! item.remote_product_id, item.num_wished, @form_token
            rescue Exception => e
              STDERR.puts e.message.to_s
              STDERR.puts e.backtrace
              ordered_qty = nil
              item.update(state: "error")
            end

            item.update(num_ordered: ordered_qty.to_i)

            log_result item

            yield item if block_given?
          else
            @logger.warn("Cannot order this item (no rem. prod/num_wished)")
            @logger.warn(item.attributes)
          end
        end
        @order.update(ordered_at: DateTime.now)
      end

      # Returns diff -> perfect: [], ...
      def check_against_cart
        diff = {perfect: [], under_avail: [], extra: [], modified: [], miss: [], error: []}.to_h
        # have logger
        mech = Rawbotz::new_mech
        mech.login
        cart_c = mech.get_cart_content
        cart = cart_c.map{|i| [i[0],i[1]]}.to_h

        @order.order_items.processible.find_each do |item|
          remote_name = item.local_product.try(:remote_product).try(:name)
          qty = cart.delete remote_name
          # missing case: more than wanted
          if !qty.nil?
            # Is in cart
            if qty.to_i == item.num_wished && qty.to_i == item.num_ordered
              diff[:perfect] << [item, qty.to_i]
            elsif qty.to_i == item.num_ordered
              diff[:under_avail] << [item, qty.to_i]
            else
              # + information qty.to_i
              diff[:modified] << [item, qty.to_i]
            end
          else
            diff[:miss] << [item, item.num_wished]
            # probably not available
          end
        end
        cart.each do |name, qty|
          diff[:extra] << [name, qty]
        end

        @order.order_items.where(state: "error").find_each do |item|
          diff[:error] << [item.local_product.name]
        end

        diff
      end

      private

      def log_product_handling item
        @logger.info ("Will put in cart: #{item.remote_product_id}: #{item.num_wished}")
        @logger.debug ("  Local  Product: #{item.local_product.name}")
        @logger.debug ("  Remote Product: #{item.local_product.remote_product.name}")
      end

      def log_result item
        if item.state == "error"
          @logger.warn "Error when ordering #{item.num_wished} #{item.local_product.name}"
        end
        if item.out_of_stock?
          @logger.info "Product out of stock"
        elsif !item.all_ordered?
          @logger.info "Only #{item.num_ordered} (of #{item.num_wished}) could be ordered."
        else
          @logger.info "Ordered #{item.num_ordered} (of #{item.num_wished})."
        end
      end
    end
  end
end
