module Redmineup
  module ActsAsJournalized
    class Hook < Redmine::Hook::Listener
      def after_plugins_loaded(_context)
        return unless Gem::Version.new(Redmine::VERSION.to_s) >= Gem::Version.new('5.0')

        require File.expand_path('journal_patch', __dir__)
        require File.expand_path('journal_event', __dir__)
        ::Journal.prepend(JournalPatch) unless ::Journal.include?(JournalPatch)
        Redmineup::ActsAsJournalized.journalized_classes.each do |klass|
          Redmineup::ActsAsJournalized.register_activity(klass) if klass.up_journalized_options[:activity]
        end
      end
    end
  end
end
