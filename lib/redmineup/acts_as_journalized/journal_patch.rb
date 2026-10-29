module Redmineup
  module ActsAsJournalized
    module JournalPatch
      def self.prepended(base)
        base.extend(ClassMethods)
        base.singleton_class.prepend(IssueOnlyVisible)
      end

      module IssueOnlyVisible
        def visible(*)
          super.where(journalized_type: 'Issue')
        end
      end

      module ClassMethods
        def up_project_ids(options)
          project = options[:project]
          return [project.id] unless options.fetch(:with_subprojects, Setting.display_subprojects_issues?)

          project.self_and_descendants.ids
        end

        def visible_for(user = User.current, options = {})
          conditions = Redmineup::ActsAsJournalized.journalized_classes.map do |klass|
            raise ArgumentError, "#{klass.name} must define scope :visible" unless klass.respond_to?(:visible)

            visible = klass.visible(user).reorder(nil)
            visible = visible.where(klass.table_name => { project_id: up_project_ids(options) }) if options[:project] && klass.column_names.include?('project_id')
            visible = visible.except(:eager_load).left_outer_joins(*visible.eager_load_values) if visible.eager_load_values.any?
            sanitize_sql_array(
              ["#{table_name}.journalized_type = ? AND #{table_name}.journalized_id IN (#{visible.select(klass.arel_table[:id]).to_sql})",
               klass.base_class.name]
            )
          end
          conditions.empty? ? none : where(conditions.join(' OR '))
        end
      end

      def up_journalized?
        journalized.respond_to?(:up_journalized?)
      end

      def up_start_blank
        @attributes_before_change = {}
        @custom_values_before_change = {}
      end

      def editable_by?(usr)
        return super unless up_journalized?

        permission = journalized.up_journalized_options[:edit_notes_permission]
        return false unless permission && usr&.logged?

        if permission.respond_to?(:call)
          permission.call(self, usr)
        else
          usr.allowed_to?(permission, journalized.project)
        end
      end

      def up_update_notes(usr, text)
        return false unless editable_by?(usr)

        self.notes = text
        self.updated_by_id = usr.id if has_attribute?(:updated_by_id)
        save
      end

      private

      def add_watcher
        super unless up_journalized?
      end

      def split_private_notes
        up_journalized? || super
      end

      def send_notification
        return super unless up_journalized?

        notifier = journalized.up_journalized_options[:notify]
        notifier&.call(self) if notify?
      end
    end
  end
end
