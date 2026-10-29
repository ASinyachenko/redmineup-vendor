require File.dirname(__FILE__) + '/test_helper'
require 'yaml'

class LocalesTest < ActiveSupport::TestCase
  Dir[File.expand_path('../../config/locales/*.yml', __FILE__)].sort.each do |file|
    name = File.basename(file, '.yml')

    define_method("test_#{name}_root_key_is_the_locale_name_string") do
      assert_equal [name], YAML.load_file(file).keys
    end
  end
end
