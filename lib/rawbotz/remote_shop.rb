require 'magento_remote'

module Rawbotz
  def self.mech
    settings = (YAML.load_file Rawbotz.conf_file_path)["remote_shop"]
    mech = MagentoMech.new settings["base_uri"]
    mech.pass = settings["pass"]
    mech.user = settings["user"]
    mech.login
    mech
  end
  def self.attribute_ids
    @@attribute_ids ||= (YAML.load_file Rawbotz.conf_file_path)["attribute_ids"]
  end
end
