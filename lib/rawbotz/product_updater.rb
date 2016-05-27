module Rawbotz
  class ProductUpdater
    attr_accessor :local_products
    attr_accessor :logger
    attr_accessor :name_attribute_id, :supplier_attribute_id,
      :shelve_attribute_id, :packsize_attribute_id

    def initialize logger
      @local_products = {}
      @logger = logger
      # Attribute mapping from conf
      @name_attribute_id     = Rawbotz.attribute_ids["name"]
      @supplier_attribute_id = Rawbotz.attribute_ids["supplier_name"]
      @shelve_attribute_id   = Rawbotz.attribute_ids["shelve_nr"]
      @packsize_attribute_id = Rawbotz.attribute_ids["packsize"]
      @logger.debug "Attribute-ids: Name: #{@name_attribute_id}, "\
        "Supplier: #{@supplier_attribute_id}, "\
        "Shelve-Nr: #{@shelve_attribute_id}, "\
        "Packsize: #{@packsize_attribute_id}"
    end

    def sync
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

      log_changes

      save_changes
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

    def ensure_existence
      RawgentoDB::Query.products.each do |p|
        #@logger.info("Ensuring product #{p.product_id} exists")
        l = RawgentoModels::LocalProduct.unscoped.find_or_initialize_by(product_id: p.product_id)
        @local_products[p.product_id] = l
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
