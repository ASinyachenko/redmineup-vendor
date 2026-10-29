# The MIT License (MIT)

# Copyright (c) 2016-2018 Georg Ledermann

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Redmineup
  module ActsAsDraftable #:nodoc: all
    module Base
      ALLOWED_DRAFT_OPTIONS = [:parent]

      def draftable?
        false
      end

      def up_acts_as_draftable(options = {})
        raise ArgumentError unless options.is_a?(Hash)
        raise ArgumentError unless options.keys.all? { |k| ALLOWED_DRAFT_OPTIONS.include?(k) }

        class_attribute :draft_parent

        if options[:parent]
          parent_class = self.reflect_on_all_associations(:belongs_to).find { |a| a.name == options[:parent] }.try(:klass)
          raise ArgumentError unless parent_class

          unless parent_class.method_defined?(:drafts)
            parent_class.class_eval do
              def drafts(user)
                Draft.where(user: user, parent: self)
              end

              def self.child_drafts(user)
                Draft.where(user: user, parent_type: self.base_class.name)
              end
            end
          end

          self.draft_parent = options[:parent]
        end

        attr_accessor :draft_id
        before_save :clear_draft

        extend Redmineup::ActsAsDraftable::ClassMethods
        include Redmineup::ActsAsDraftable::InstanceMethods
      end
    end # Base

    module ClassMethods
      def draftable?
        true
      end

      def from_draft(draft_or_id)
        draft = draft_or_id.is_a?(Draft) ? draft_or_id : Draft.find(draft_or_id)
        raise ArgumentError unless draft.target_type == name

        target = draft.target_type.constantize.new
        target.load_from_draft(draft.data)

        target.draft_id = draft.id
        target
      end

      def drafts(user = nil)
        drafts = Draft.where(target_type: name)
        drafts = drafts.where(user_id: user.id) if user
        drafts
      end
    end # ClassMethods

    module InstanceMethods
      def save_draft
        return false unless new_record? || changed?

        draft = self.draft || Draft.new
        draft.data = dump_to_draft
        draft.user_id = User.current.try(:id)
        draft.parent = parent_for_draft
        draft.target_type = self.class.name

        result = draft.save
        self.draft_id = draft.id if result
        result
      end

      def update_draft(attributes)
        with_transaction_returning_status do
          assign_attributes(attributes)
          save_draft
        end
      end

      def draft
        Draft.find_by_id(draft_id)
      end

      def parent_for_draft
        return self if id.present?

        self.class.draft_parent.present? ? send(self.class.draft_parent) : self
      end

      def last_draft
        @last_draft ||= Redmineup::ActsAsDraftable::Draft.where(
          target_type: self.class.name,
          parent_type: parent_for_draft.try(:class).try(:to_s),
          parent_id:   parent_for_draft.try(:id),
          user_id:     User.current.try(:id)
        ).last
      end

      def dump_to_draft
        instance_values.default = nil
        Marshal.dump(instance_values)
      end

      def load_from_draft(string)
        values = Marshal.load(string)

        values.each do |name, value|
          instance_variable_set("@#{name}", value)
        end
      end

      def clear_draft
        if last_draft && last_draft.destroy
          self.draft_id = nil
        end
      end
    end # InstanceMethods

    module Migration
      def create_drafts_table
        return if connection.table_exists?(:drafts)

        connection.create_table :drafts do |t|
          t.string :target_type, limit: 150, null: false
          t.references :user
          t.references :parent, polymorphic: true
          t.binary :data, limit: 16777215, null: false
          t.datetime :updated_at, null: false
        end

        connection.add_index :drafts, [:user_id, :target_type]
      end

      def drop_drafts_table
        connection.drop_table :drafts if connection.table_exists?(:drafts)
      end
    end # Migration
  end
end

ActiveRecord::Base.extend Redmineup::ActsAsDraftable::Base
ActiveRecord::Base.extend Redmineup::ActsAsDraftable::Migration
