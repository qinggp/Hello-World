require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  def test_validate_presence_of
    page = Page.new
    assert_no_difference 'Page.count' do
      assert !page.valid?
      assert page.errors.invalid?(:body)
      assert page.errors.invalid?(:page_id)
      assert page.errors.invalid?(:title)
    end
  end

end
