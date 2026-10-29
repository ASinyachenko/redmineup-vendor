require 'rails/all'
require 'redmineup'
require 'minitest/autorun'
require 'minitest/mock'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.configurations = YAML.load_file(File.dirname(__FILE__) + '/database.yml')
ActiveRecord::Base.establish_connection(ENV['DB'].try(:to_sym) || :sqlite)

load(File.dirname(__FILE__) + '/schema.rb')
Dir.glob(File.expand_path('models/*.rb', __dir__)).each { |f| require f }

class ActiveSupport::TestCase # :nodoc:
  include ActiveRecord::TestFixtures

  gem_fixtures_path = File.dirname(__FILE__) + '/fixtures/'
  respond_to?(:fixture_paths=) ? self.fixture_paths = [gem_fixtures_path] : self.fixture_path = gem_fixtures_path 

  self.use_transactional_tests = true if RUBY_VERSION > '1.9.3'
  self.use_instantiated_fixtures = false
  set_fixture_class tags: Redmineup::ActsAsTaggable::Tag
  set_fixture_class taggings: Redmineup::ActsAsTaggable::Tagging

  set_fixture_class votable_caches: VotableCache
  fixtures :all

  def assert_equivalent(expected, actual, message = nil)
    if expected.first.is_a?(ActiveRecord::Base)
      assert_equal expected.sort_by(&:id), actual.sort_by(&:id), message
    else
      assert_equal expected.sort, actual.sort, message
    end
  end

  def assert_tag_counts(tags, expected_values)
    # Map the tag fixture names to real tag names
    expected_values = expected_values.each_with_object({}) do |(tag, count), hash|
      hash[tags(tag).name] = count
    end

    tags.each do |tag|
      value = expected_values.delete(tag.name)

      assert_not_nil value, "Expected count for #{tag.name} was not provided"
      assert_equal value, tag.count, "Expected value of #{value} for #{tag.name}, but was #{tag.count}"
    end

    return if expected_values.empty?

    assert false, "The following tag counts were not present: #{expected_values.inspect}"
  end

  # From Rails trunk
  def assert_difference(expressions, difference = 1, message = nil, &block)
    expression_evaluations = [expressions].flatten.collect { |expression| -> { eval(expression, block.binding) } }

    original_values = expression_evaluations.inject([]) { |memo, expression| memo << expression.call }
    yield
    expression_evaluations.each_with_index do |expression, i|
      assert_equal original_values[i] + difference, expression.call, message
    end
  end

  def assert_no_difference(expressions, message = nil, &block)
    assert_difference expressions, 0, message, &block
  end
end
