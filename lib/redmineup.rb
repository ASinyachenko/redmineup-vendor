require 'active_record'
require 'action_view'

require 'redmineup/version'
require 'redmineup/engine'

require 'redmineup/settings'
require 'redmineup/settings/money'

require 'redmineup/acts_as_list/list'
require 'redmineup/acts_as_taggable/tag'
require 'redmineup/acts_as_taggable/tag_list'
require 'redmineup/acts_as_taggable/tagging'
require 'redmineup/acts_as_taggable/up_acts_as_taggable'
require 'redmineup/acts_as_viewed/up_acts_as_viewed'
require 'redmineup/acts_as_votable/up_acts_as_votable'
require 'redmineup/acts_as_votable/up_acts_as_voter'
require 'redmineup/acts_as_votable/vote'
require 'redmineup/acts_as_votable/voter'
require 'redmineup/acts_as_draftable/up_acts_as_draftable'
require 'redmineup/acts_as_draftable/draft'
require 'redmineup/acts_as_priceable/up_acts_as_priceable'
require 'redmineup/acts_as_journalized/up_acts_as_journalized'

require 'redmineup/currency'
require 'redmineup/helpers/tags_helper'
require 'redmineup/money_helper'
require 'redmineup/colors_helper'

require 'liquid'
require 'redmineup/liquid/filters/additional'
require 'redmineup/liquid/filters/base'
require 'redmineup/liquid/filters/arrays'
require 'redmineup/liquid/filters/colors'
require 'redmineup/liquid/drops/issues_drop'
require 'redmineup/liquid/drops/news_drop'
require 'redmineup/liquid/drops/projects_drop'
require 'redmineup/liquid/drops/users_drop'
require 'redmineup/liquid/drops/time_entries_drop'
require 'redmineup/liquid/drops/attachment_drop'
require 'redmineup/liquid/drops/issue_relations_drop'
require 'redmineup/liquid/drops/version_drop'
require 'redmineup/liquid/drops/custom_field_enumeration_drop'

require 'redmineup/helpers/external_assets_helper'
require 'redmineup/helpers/journals_helper'
require 'redmineup/helpers/form_tag_helper'
require 'redmineup/helpers/calendars_helper'
require 'redmineup/helpers/datetime_helper'
require 'redmineup/helpers/test_helper'
require 'redmineup/assets_manager'

require 'redmineup/patches/liquid_patch'

module Redmineup
  GEM_NAME = 'redmineup'.freeze

  def self.plugin_installed?(plugin_id)
    Rails.root.join("plugins/#{plugin_id}/init.rb").exist?
  end

  def self.cable_available?
    Rails.version > '4.0'
  end
end

require 'application_record' if !defined?(ApplicationRecord) && Rails.version < '7.2.2'

if Redmineup.cable_available?
  require 'action_cable/server/rup_configuration'
  require 'action_cable/server/rup_server'
  require 'action_cable/connection/rup_connection'
  require 'redmineup/patches/action_cable_base_patch'
  require 'redmineup/patches/action_cable_patch'
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, Redmineup::ActsAsList::List
  ActiveRecord::Base.extend(Redmineup::ActsAsVotable::Voter)
  ActiveRecord::Base.extend(Redmineup::ActsAsVotable::Votable)
end

if defined?(Propshaft::Assembly)
  Propshaft::Assembly.prepend(Module.new do
    def self.prepended(base)
      base.class_eval do
        cattr_accessor :redmineup_patched
      end
    end

    def config
      return super if self.class.redmineup_patched

      original_config = super
      if defined?(Redmine::AssetPath)
        base_dir = Pathname.new(Redmineup::AssetsManager.base_path)
        paths = Redmineup::AssetsManager.assets_paths.map { |path| Pathname.new(path)}
        asset_prefix = "plugin_assets/#{Redmineup::GEM_NAME}"

        original_config[:redmine_extension_paths] << Redmine::AssetPath.new(base_dir, paths, asset_prefix)
        self.class.redmineup_patched = true
      end
      original_config
    end
  end)
else
  Redmineup::AssetsManager.install_assets
end

if defined?(ActionView::Base)
  ActionView::Base.send :include, Redmineup::CalendarsHelper
  ActionView::Base.send :include, Redmineup::ExternalAssetsHelper
  ActionView::Base.send :include, Redmineup::FormTagHelper
  ActionView::Base.send :include, Redmineup::JournalsHelper
  ActionView::Base.send :include, Redmineup::TagsHelper
end

def requires_redmineup(arg)
  arg = { version_or_higher: arg } unless arg.is_a?(Hash)
  arg.assert_valid_keys(:version_or_higher)

  requirement = arg[:version_or_higher]
  unless requirement.is_a?(String)
    raise ArgumentError, ':version_or_higher accepts a version string only'
  end

  current = Gem::Version.new(Redmineup::VERSION)
  required = Gem::Version.new(requirement)

  return true if required <= current

  message = "Redmine requires redmineup gem version #{requirement} or higher " \
            "(you're using #{Redmineup::VERSION}).\n" \
            "Please update with 'bundle update redmineup --conservative'."
  Rails.logger&.error("\033[31m[ERROR]\033[0m #{message}")
  abort "\033[31m#{message}\033[0m"
end
