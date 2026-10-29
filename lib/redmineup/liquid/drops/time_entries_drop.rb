module Redmineup
  module Liquid
    class TimeEntriesDrop < ::Liquid::Drop
      def initialize(time_entries)
        @time_entries = time_entries
      end

      def all
        @all ||= @time_entries.map do |time_entry|
          TimeEntryDrop.new time_entry
        end
      end

      def visible
        @visible ||= @all.select(&:visible?)
      end

      def each(&block)
        all.each(&block)
      end

      def size
        @time_entries.size
      end
    end

    class TimeEntryDrop < ::Liquid::Drop
      include ActionView::Helpers::UrlHelper

      delegate :id,
               :hours,
               :comments,
               :spent_on,
               :tyear,
               :tmonth,
               :tweek,
               :visible?,
               :updated_on,
               :created_on,
               :to => :@time_entry, 
               allow_nil: true

      def initialize(time_entry)
        @time_entry = time_entry
      end

      def user
        @user ||= UserDrop.new(@time_entry.user)
      end

      def issue
        @issue ||= IssueDrop.new(@time_entry.issue) unless @time_entry.issue.blank?
      end

      def activity
        @activity ||= @time_entry.activity && @time_entry.activity.name
      end

      def custom_field_values
        @time_entry.custom_field_values
      end      

    end
  end
end
