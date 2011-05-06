require 'rubygems'
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper
end

require 'test/unit'
class Test::Unit::TestCase
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
end

require File.expand_path(File.dirname(__FILE__) + "/blueprints")
# NOTE: 拡張機能の blueprint.rb 読み込み
Object.subclasses_of(Mars::Extension).map(&:instance).map(&:root).each do |root|
  blueprint_path = File.join(root, "test", "blueprints.rb")
  require blueprint_path if File.exist?(blueprint_path)
end

def set_mobile_user_agent(user_agent = "SoftBank")
  @request.user_agent = user_agent
end

def set_mobile_user_agent_docomo
  @request.user_agent = "DoCoMo/2.0"
  # FIXME: :key が入っておらずJpMobileのtransit_idで落ちるため追記
  @request.session_options[:key] = "_mars_session_id"
end

# メールのセットアップ
def setup_emails
  @emails = ActionMailer::Base.deliveries
  @emails.clear
end

private

def make_mail_text(opts = {})
  mail = TMail::Mail.new

  mail.from = opts[:from]
  mail.to = opts[:to]
  mail.sender = opts[:sender]
  mail.subject = NKF.nkf("-jM", opts[:subject])
  mail.date = Time.now

  attach = TMail::Mail.new
  attach.body = opts[:body]
  attach.set_content_type 'text', 'plain', {'charset'=>'iso-2022-jp'}
  attach.transfer_encoding = '7bit'
  mail.parts.push attach

  if opts[:file_paths]
    opts[:file_paths].zip(opts[:content_types]) do |file_path, content_type|
      attach = TMail::Mail.new
      attach.body = Base64.encode64(IO.read(file_path))
      attach.set_content_type(content_type[0], content_type[1],
                              'name' => File.basename(file_path))
      attach.set_content_disposition 'attachment', 'filename' => File.basename(file_path)
      attach.transfer_encoding = 'base64'
      mail.parts.push attach
    end
  end

  mail.encoded
end
