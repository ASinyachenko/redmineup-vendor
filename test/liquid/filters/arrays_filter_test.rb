require File.dirname(__FILE__) + '/../liquid_helper'
include LiquidHelperMethods

module Redmineup
  class ArraysFilterTest < ActiveSupport::TestCase
    def setup
      @liquid_render = LiquidRender.new
      @array = '6,7,8,9,1,2,3,4,5'
    end

    def test_first_filter
      assert_match '1', @liquid_render.render("{{ '#{@array}' | split: ',' | first: 5 | last }}")
    end

    def test_sort_filter
      assert_match '123456789', @liquid_render.render("{{ '#{@array}' | split: ',' | sort }}")
    end

    def test_where_filter
      assert_match ws('{"name"=>"two", "value"=>5}'), ws(@liquid_render.render("{{ objects_arr | where: 'name', 'two' }}"))
      assert_match ws('{"name"=>"one", "value"=>10}'), ws(@liquid_render.render("{{ objects_arr | where: 'value', 6, '>' }}"))
      assert_match ws('{"name"=>"one", "value"=>10}'), ws(@liquid_render.render("{{ objects_arr | where: 'name', 'on', 'match' }}"))
      assert_match '3', @liquid_render.render("{{ objects_arr | where: 'value', '', 'any' | size }}")
      assert_match '1', @liquid_render.render("{{ objects_arr | where: 'value', '', 'none' | size }}")
      assert_match '2', @liquid_render.render("{{ issues.all | where: 'author.name', 'Jonathan', '==' | size }}")
      assert_match '1', @liquid_render.render("{{ issues.all | where: 'author.language', 'CH', '==' | size }}")
      assert_match '0', @liquid_render.render("{{ issues.all | where: 'author.name', '', 'none' | size }}")
    end

    def ws(string)
      string.delete(' ')
    end
  end
end
