module Redmineup
  class JournalEvent < ::Journal
    def self.visible(user = User.current, options = {})
      visible_for(user, options)
    end

    def event_title
      title = up_activity_options[:title]
      title ? title.call(self) : journalized.to_s
    end

    def event_url(options = {})
      up_activity_options[:url].call(self).merge(options)
    end

    def event_type
      up_activity_options[:css_type] || "#{journalized_type.underscore.dasherize}-edit"
    end

    def event_group
      journalized
    end

    private

    def up_activity_options
      journalized.up_journalized_options[:activity]
    end
  end
end
