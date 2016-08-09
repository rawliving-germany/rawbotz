module Rawbotz
  class ProductUpdater
    attr_accessor :local_products
    attr_accessor :logger
    attr_accessor :name_attribute_id, :supplier_attribute_id,
      :shelve_attribute_id, :packsize_attribute_id,
      :supplier_sku_attribute_id, :supplier_prod_name_attribute_id,
      :order_info_attribute_id, :purchase_price_attribute_id
    attr_accessor :change_text

    def initialize logger
      @local_products = {}
      @logger = logger
      # Attribute mapping from conf
      @name_attribute_id     = Rawbotz.attribute_ids["name"]
      @supplier_attribute_id = Rawbotz.attribute_ids["supplier_name"]
      @shelve_attribute_id   = Rawbotz.attribute_ids["shelve_nr"]
      @packsize_attribute_id = Rawbotz.attribute_ids["packsize"]
      @order_info_attribute_id   = Rawbotz.attribute_ids["order_info"]
      @supplier_sku_attribute_id = Rawbotz.attribute_ids["supplier_sku"]
      @purchase_price_attribute_id     = Rawbotz.attribute_ids["purchase_price"]
      @supplier_prod_name_attribute_id = Rawbotz.attribute_ids["supplier_prod_name"]
      @logger.debug "Attribute-ids: Name: #{@name_attribute_id}, "\
        "Supplier: #{@supplier_attribute_id}, "\
        "Shelve-Nr: #{@shelve_attribute_id}, "\
        "Packsize: #{@packsize_attribute_id}"\
        "Order Info: #{@order_info_attribute_id}"\
        "Purchase Price: #{@purchase_price_attribute_id}"\
        "Supplier-SKU: #{@supplier_sku_attribute_id}"\
        "Supplier-Prod-Name: #{@supplier_prod_name_attribute_id}"
    end

    def sync(dry_run=false)
      ensure_existence

      @logger.info "#{@local_products.count} products"
      # Name
      update_attribute(@name_attribute_id, :name)
      # Supplier
      update_supplier_from_option(@supplier_attribute_id)
      # Shelve
      update_attribute(@shelve_attribute_id, :shelve_nr)
      # Packsize
      update_attribute(@packsize_attribute_id, :packsize, :integer)
      # Supplier SKU
      update_attribute(@supplier_sku_attribute_id, :supplier_sku)
      # Supplier Product name
      #update_attribute(@supplier_prod_name_attribute_id, :supplier_prod_name)
      update_names
      # Order Info
      update_attribute(@order_info_attribute_id, :order_info)
      # Purchase Price
      update_attribute(@purchase_price_attribute_id, :purchase_price)

      log_changes

      @change_text = changes

      save_changes if !dry_run
    end

    private

    def save_changes
      RawgentoModels::LocalProduct.transaction do
        @local_products.values.each(&:save!)
      end
    end

    def log_changes
      @local_products.values.each do |p|
        if false && p.dirty?
          @logger.info "something changed"
        end
        if p.changed?
          @logger.info("Changes for #{p.product_id} (#{p.name}): #{p.changes}")
        end
      end
    end

    def changes
      local_changed_products = @local_products.values.select {|p| p.changed? }
      changes_string = local_changed_products.map do |p|
        "Changes for #{p.product_id} (#{p.name}): #{p.changes}"
      end.join("\n")
    end

    def ensure_existence
      RawgentoDB::Query.products.each do |p|
        #@logger.info("Ensuring product #{p.product_id} exists")
        l = RawgentoModels::LocalProduct.unscoped.find_or_initialize_by(product_id: p.product_id)
        @local_products[p.product_id] = l
      end
    end

    # This works at least for magento 1.7, later versions might require
    # attribute name update
    def update_names
      RawgentoDB::Query.product_names().each do |product_id, name|
        p = @local_products[product_id]
        if p
          p.assign_attributes(name: name)
        end
      end
    end

    # Fetches magento attribute and sets corresponding values
    def update_attribute attribute_id, attribute_sym, type=:varchar
      RawgentoDB::Query.attribute_varchar(attribute_id).each do |product_id, value|
        p = @local_products[product_id]
        if type == :integer && !value.nil? && value.to_s != ""
          p.assign_attributes(attribute_sym => value.to_i)
        else
          p.assign_attributes(attribute_sym => value)
        end
        #@logger.info "Updating #{attribute_sym.to_s} of #{product_id}: #{value}"
      end
    end

    def update_supplier_from_option attribute_id
      RawgentoDB::Query.attribute_option(attribute_id).each do |product_id, value|
        p = @local_products[product_id]
        supplier = RawgentoModels::Supplier.find_or_create_by(name: value)
        p.supplier = supplier
        #logger.info "Updating supplier of #{product_id}: #{value}"
      end
    end
  end
end
