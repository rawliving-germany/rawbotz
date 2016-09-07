require 'minitest'
require 'minitest/autorun'
require 'ostruct'

require 'rawbotz/models/order_mail'
require 'rawbotz/mail_template'

#require 'ostruct'

class OrderMailTest < MiniTest::Test
  def default_template
    "Dear SUPPLIERNAME\n"\
    "SUBJECT=I mail you SUPPLIERNAME\n"\
    "\n"\
    " \n"\
    "* SUPPLIERSKU QTY (NUM_PACKS of PACKSIZE) PRODUCTNAME\n"\
    "see you"
  end

  def test_creation
    supplier = { name: "Suppliername",
                 email: "mailme@plea.se read@th.at one@co.py",
                 order_template: default_template }
    order = OpenStruct.new supplier: supplier, order_items: []
    order_mail = Rawbotz::MailTemplate.create(order)
    assert_equal "mailme@plea.se",               order_mail.to
    assert_equal ["read@th.at", "one@co.py"],    order_mail.cc
    assert_equal "I mail you Suppliername",      order_mail.subject
    assert_equal "Dear Suppliername\n\n \nsee you", order_mail.body
  end

  def test_mailto_url
    supplier = { name: "Suppliername",
                 email: "mailme@plea.se read@th.at one@co.py",
                 order_template: default_template }
    order = OpenStruct.new supplier: supplier, order_items: []
    order_mail = Rawbotz::MailTemplate.create(order)

    assert_equal "mailto:mailme@plea.se?cc=read@th.at&cc=one@co.py&Subject=I mail you Suppliername&body=Dear%20Suppliername%0A%0A%20%0Asee%20you",
      order_mail.mailto_url
  end
end

