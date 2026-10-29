module Redmineup
  module ActsAsJournalized
    EXCLUDED_ATTRIBUTES = %w(id created_on updated_on created_at updated_at lock_version).freeze
    OPTION_KEYS = %i[association associations only except journalize_create activity notify edit_notes_permission detail_formatter].freeze

    def self.registry
      @registry ||= []
    end

    def self.journalized_classes
      registry.filter_map(&:safe_constantize)
    end

    def self.register_activity(klass)
      return unless defined?(::Redmineup::JournalEvent)

      activity = klass.up_journalized_options[:activity]
      type = (activity[:type] || "#{klass.name.underscore}_journals").to_s
      class_name = klass.name
      ::Redmineup::JournalEvent.acts_as_activity_provider(
        type: type,
        author_key: :user_id,
        scope: -> { ::Redmineup::ActsAsJournalized.activity_scope(class_name.constantize) }
      )
    end

    def self.activity_scope(klass)
      keys = Array(klass.up_journalized_options[:activity][:keys]).map(&:to_s)
      scope = ::Redmineup::JournalEvent.preload(:user, :journalized).where(journalized_type: klass.base_class.name)
      notes = "#{::Journal.table_name}.notes <> ''"
      return scope.where(notes) if keys.empty?

      details = ::JournalDetail.table_name
      scope.joins("LEFT OUTER JOIN #{details} ON #{details}.journal_id = #{::Journal.table_name}.id")
           .where("#{notes} OR (#{details}.property = 'attr' AND #{details}.prop_key IN (?))", keys).distinct
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def up_acts_as_journalized(options = {})
        options.assert_valid_keys(*OPTION_KEYS)
        if options[:activity] && !options[:activity][:url].respond_to?(:call)
          raise ArgumentError, 'up_acts_as_journalized: activity needs :url lambda'
        end

        class_attribute :up_journalized_options, instance_writer: false
        self.up_journalized_options = options

        has_many options.fetch(:association, :journals), as: :journalized, class_name: 'Journal', dependent: :destroy, inverse_of: :journalized
        (options[:associations] || {}).each do |association, attributes|
          attributes.each do |attribute|
            define_method("#{association}_#{attribute}") { public_send(association)&.public_send(attribute) }
          end
        end
        before_save :up_prepare_journal
        after_save :up_save_journal
        include InstanceMethods
        include NoCustomFields unless method_defined?(:custom_field_values)

        Redmineup::ActsAsJournalized.registry << name unless Redmineup::ActsAsJournalized.registry.include?(name)
        Redmineup::ActsAsJournalized.register_activity(self) if options[:activity]
      end
    end

    module NoCustomFields
      def custom_field_values
        []
      end
    end

    module InstanceMethods
      def up_journalized?
        true
      end

      def init_journal(user = User.current, notes = '')
        @current_journal ||= Journal.new(journalized: self, user: user, notes: notes).tap do
          @tag_list = Redmineup::ActsAsTaggable::TagList.new(*@tag_list) if @tag_list
        end
      end

      def current_journal
        @current_journal
      end

      def clear_journal
        @current_journal = nil
      end

      def journalized_attribute_names
        options = up_journalized_options
        names = self.class.column_names - EXCLUDED_ATTRIBUTES - Array(options[:except]).map(&:to_s)
        names = names.reject { |name| name.end_with?('_count') }
        names &= Array(options[:only]).map(&:to_s) if options[:only]
        names << 'tag_list' if respond_to?(:tag_list) && !Array(options[:except]).map(&:to_s).include?('tag_list')
        names + (options[:associations] || {}).flat_map { |association, attributes| attributes.map { |attribute| "#{association}_#{attribute}" } }
      end

      private

      def up_prepare_journal
        current_journal.up_start_blank if current_journal && new_record? && up_journalized_options[:journalize_create]
      end

      def up_save_journal
        return unless current_journal

        current_journal.save
        clear_journal
      end
    end
  end
end

ActiveRecord::Base.include Redmineup::ActsAsJournalized
