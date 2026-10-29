module Redmineup
  class Engine < Rails::Engine
    config.to_prepare do
      next unless defined?(::Redmine::Plugin)

      require 'auto_completes_controller'

      require File.expand_path('../redmineup/patches/compatibility_patch', __dir__)
      require File.expand_path('../redmineup/patches/auto_completes_controller_patch', __dir__)

      require File.expand_path('../redmineup/hooks/views_layouts_hook', __dir__)

      require File.expand_path('../redmineup/acts_as_journalized/hook', __dir__)
    end
  end
end
