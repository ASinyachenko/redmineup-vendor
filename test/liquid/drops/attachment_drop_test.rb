require File.dirname(__FILE__) + '/../liquid_helper'

module Redmineup
  class AttachmentDropTest < ActiveSupport::TestCase
    def setup
      @attachment = attachments(:attachment_001)
      @user = @attachment.author
      @liquid_render = LiquidRender.new('attachment' => Liquid::AttachmentDrop.new(@attachment))
    end

    def test_author
      assert_equal @user.name, @liquid_render.render('{{ attachment.author.name }}')
    end
  end
end
