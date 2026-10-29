require File.dirname(__FILE__) + '/../liquid_helper'
include LiquidHelperMethods

module Redmineup
  class ColorsFilterTest < ActiveSupport::TestCase
    
    def setup
      @liquid_render = LiquidRender.new
    end

    def test_hex_color
      assert_match '#ff0000', @liquid_render.render("{{ 'red' | hex_color }}")
    end

    def test_darken_color
      assert_match '#000066', @liquid_render.render("{{ 'blue' | darken_color }}")
    end

    def test_lighten_color
      assert_match '#9999ff', @liquid_render.render("{{ 'blue' | lighten_color }}")
    end

    def test_contrasting_text_color
      assert_match '#9999ff', @liquid_render.render("{{ 'blue' | contrasting_text_color }}")
    end

    def test_convert_to_brightness_value
      assert_match '15', @liquid_render.render("{{ 'blue' | convert_to_brightness_value }}")
    end


  end
end
