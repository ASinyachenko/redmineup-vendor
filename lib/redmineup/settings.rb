module Redmineup
  class Settings
    SECTIONS = {
      'money' => { id: :money, label: :label_redmineup_money, partial: 'money' }
    }.freeze

    class << self
      def initialize_gem_settings
        return if !Object.const_defined?('Setting') || Setting.respond_to?(:plugin_redmineup)

        if Setting.respond_to?(:define_setting)
          Setting.send(:define_setting, 'plugin_redmineup', 'default' => default_settings, 'serialized' => true)
        elsif Setting.respond_to?(:available_settings)
          Setting.available_settings['plugin_redmineup'] = { 'default' => default_settings, 'serialized' => true }
          Setting.class.send(:define_method, 'plugin_redmineup', -> { Setting['plugin_redmineup'] })
          Setting.class.send(:define_method, 'plugin_redmineup=', lambda do |val|
            setting = find_or_default('plugin_redmineup')
            setting.value = val || ''
            @cached_settings['plugin_redmineup'] = nil
            setting.save(validate: false)
            setting.value
          end)
        end
        @settings_initialized
      end

      # Use apply instead attrs assign because it can rewrite other attributes
      def apply=(values)
        initialize_gem_settings unless @settings_initialized

        Setting.plugin_redmineup = Setting.plugin_redmineup.merge(values)
      end

      def values
        initialize_gem_settings unless @settings_initialized
        Object.const_defined?('Setting') ? Setting.plugin_redmineup : {}
      end

      def [](value)
        initialize_gem_settings unless @settings_initialized
        return Setting.plugin_redmineup[value] if Object.const_defined?('Setting')

        nil
      end

      private

      def default_settings
        {}
      end
    end
  end
end
