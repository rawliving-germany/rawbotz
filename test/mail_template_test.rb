require 'minitest'
require 'minitest/autorun'

require 'rawbotz/mail_template'

class MailTemplateTest < MiniTest::Test
  def test_substitution
    template = "Dear SUPPLIERNAME\n"\
      "SUBJECT=I mail you SUPPLIERNAME\n"\
      "\n"\
      " \n"\
      "* PRODUCTCODE QTY (NUM_PACKS of PACKSIZE) PRODUCTNAME\n"\
      "see you"
    order = {supplier: {name: "Suppliername"}, order_items: [
      {num_wished: 1, local_product: {name: "First Product", packsize: 4}},
      {num_wished: 5, local_product: {name: "Second Product", packsize: 5}},
      {num_wished: 7, local_product: {name: "Third Product"}}
    ]}

    expected = "Dear Suppliername\n"\
      "\n"\
      " \n"\
      " 1 (0.25 of 4) First Product\n"\
      " 5 (1.0 of 5) Second Product\n"\
      " 7 ( of ) Third Product\n"\
      "see you"
    result = Rawbotz::MailTemplate.consume(template, order)
    assert_equal expected, result
  end
end
