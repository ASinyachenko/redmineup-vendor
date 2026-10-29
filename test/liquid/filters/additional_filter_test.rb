require File.dirname(__FILE__) + '/../liquid_helper'
include LiquidHelperMethods

module Redmineup
  class AdditionalFilterTest < ActiveSupport::TestCase
    def setup
      @issue = Issue.first
      @issue_drop = Liquid::IssueDrop.new(@issue)
      @strainer = ::Liquid::Context.new.strainer
    end

    def test_parse_inline_attachments
      text = '<p>description with image <img src="screenshot.png" /></p>'
      attachment = mock_attachment
      attachments = [attachment]
      @issue_drop.define_singleton_method(:attachments) { attachments }
      Attachment.stub(:latest_attach, attachment) do
        expected_string = '<p>description with image ' \
        '<img src=\'data:image/content_type;base64,to_base64_string\'  title="attach_image" alt="attach_image" /></p>'
        assert_equal expected_string, @strainer.parse_inline_attachments(text, @issue_drop)
      end
    end

    private

    def mock_attachment
      attachment = Minitest::Mock.new
      attachment.expect(:url, 'mock_url')
      attachment.expect(:description, "attach_image")
      attachment.expect(:content_type, "content_type")
      attachment.expect(:to_base64_string, "to_base64_string")
      attachment
    end
  end
end
