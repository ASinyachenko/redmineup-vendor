module Redmineup
  module TestHelper
    module ClassMethods
      def load_plugin_fixtures(plugin_name, *names)
        fixtures_dir = File.join(Redmine::Plugin.find(plugin_name).directory, 'test', 'fixtures')
        ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, names)
      end
    end
  end
end

ActiveSupport::TestCase.extend Redmineup::TestHelper::ClassMethods