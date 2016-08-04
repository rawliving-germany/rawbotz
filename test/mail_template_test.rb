require 'minitest'
require 'minitest/autorun'

require 'rawbotz/mail_template'

require 'ostruct'

class MailTemplateTest < MiniTest::Test
  OI_BARE = OpenStruct.new({num_wished: 1, local_product: {name: "First Product", packsize: 4}})
  OI_FULL = OpenStruct.new({num_wished: 5, local_product: {name: "Second Product", packsize: 5, supplier_sku: 'sku1', supplier_prod_name: 'Suppliers first'}})
  OI_HALF = OpenStruct.new({num_wished: 7, local_product: {name: "Third Product", supplier_sku: '', supplier_prod_name: ''}})

  def test_substitution
    template = "Dear SUPPLIERNAME\n"\
      "SUBJECT=I mail you SUPPLIERNAME\n"\
      "\n"\
      " \n"\
      "* SUPPLIERSKU QTY (NUM_PACKS of PACKSIZE) PRODUCTNAME\n"\
      "see you"
    order = {supplier: {name: "Suppliername"}, order_items: [
      OI_BARE, OI_FULL, OI_HALF]}
    order = OpenStruct.new order

    expected = "Dear Suppliername\n"\
      "\n"\
      " \n"\
      " 1 (0.25 of 4) First Product\n"\
      "sku1 5 (1 of 5) Suppliers first\n"\
      " 7 ( of ) Third Product\n"\
      "see you"
    result = Rawbotz::MailTemplate.consume(template, order)
    assert_equal expected, result
  end

  def test_subject_extraction
    template = "Dear SUPPLIERNAME\n"\
      "SUBJECT=I mail you SUPPLIERNAME\n"\
      "\n"\
      " \n"\
      "* SUPPLIERSKU QTY (NUM_PACKS of PACKSIZE) PRODUCTNAME\n"\
      "see you"
    order = {supplier: {name: "Suppliername"}, order_items: [
      OI_BARE
    ]}
    order = OpenStruct.new order
    result = Rawbotz::MailTemplate.extract_subject(template, order)
    assert_equal "I mail you Suppliername", result
  end

  def test_subject_extraction_defaults_Order
    template = "Dear SUPPLIERNAME\n"\
      "* SUPPLIERSKU QTY (NUM_PACKS of PACKSIZE) PRODUCTNAME\n"\
      "see you"
    order = {supplier: {name: "Suppliername"}, order_items: [
      OI_BARE
    ]}
    order = OpenStruct.new order
    result = Rawbotz::MailTemplate.extract_subject(template, order)
    assert_equal "Order", result
  end

  def test_mailto_url_creation
    template = "Dear SUPPLIERNAME\n"\
      "SUBJECT=I mail you SUPPLIERNAME\n"\
      "\n"\
      " \n"\
      "* SUPPLIERSKU QTY (NUM_PACKS of PACKSIZE) PRODUCTNAME\n"\
      "see you"
    order = {supplier: {name: "Suppliername"}, order_items: [
      OI_BARE, OI_FULL, OI_HALF
    ]}
    order = OpenStruct.new order

    expected = "mailto:mailme@plea.se?Subject=I mail you Suppliername&body=Dear%20Suppliername%0A%0A%20%0A%201%20(0.25%20of%204)%20First%20Product%0Asku1%205%20(1%20of%205)%20Suppliers%20first%0A%207%20(%20of%20)%20Third%20Product%0Asee%20you"
    supplier = { email: "mailme@plea.se", order_template: template }
    result = Rawbotz::MailTemplate.create_mailto_url(supplier, order)
    assert_equal expected, result
  end
end
