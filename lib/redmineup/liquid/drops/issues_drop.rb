module Redmineup
  module Liquid
    class IssuesDrop < ::Liquid::Drop
      def initialize(issues)
        @issues = issues
      end

      def before_method(id)
        issue = @issues.where(id: id).first || Issue.new
        IssueDrop.new issue
      end

      def all
        @all ||=
          @issues.map do |issue|
            IssueDrop.new issue
          end
      end

      def visible
        @visible ||= @all.select(&:visible?)
      end

      def each(&block)
        all.each(&block)
      end

      def size
        @issues.size
      end
    end

    class IssueDrop < ::Liquid::Drop
      include ActionView::Helpers::UrlHelper

      delegate :id,
               :subject,
               :description,
               :visible?,
               :closed?,
               :start_date,
               :due_date,
               :overdue?,
               :done_ratio,
               :estimated_hours,
               :spent_hours,
               :total_spent_hours,
               :total_estimated_hours,
               :is_private?,
               :closed_on,
               :updated_on,
               :created_on,
               to: :@issue

      def initialize(issue)
        @issue = issue
      end

      def link
        link_to @issue.subject, url
      end

      def url
        Rails.application.routes.url_helpers.issue_path(@issue)
      end

      def author
        @user ||= UserDrop.new(@issue.author)
      end

      def assignee
        @assignee ||= UserDrop.new(@issue.assigned_to)
      end

      def attachments
        @attachments ||= @issue.attachments.map { |attachment| AttachmentDrop.new(attachment) }
      end

      def tracker
        @tracker ||= @issue.tracker && @issue.tracker.name
      end

      def status
        @status ||= @issue.status && @issue.status.name
      end

      def priority
        @priority ||= @issue.priority && @issue.priority.name
      end

      def category
        @category ||= @issue.category && @issue.category.name
      end

      def version
        @version ||= @issue.fixed_version && @issue.fixed_version.name
      end

      def time_entries
        @time_entries ||= TimeEntriesDrop.new @issue.time_entries
      end

      def parent
        @parent ||= IssueDrop.new @issue.parent if @issue.parent
      end

      def project
        @project ||= ProjectDrop.new @issue.project if @issue.project
      end

      def subtasks
        @subtasks ||= IssuesDrop.new @issue.children
      end

      def relations_from
        @relations_from ||= IssueRelationsDrop.new(@issue.relations_from.select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? })
      end

      def relations_to
        @relations_to ||= IssueRelationsDrop.new(@issue.relations_to.select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? })
      end

      def notes
        @notes ||= @issue.journals.where.not(notes: [nil, '']).order(:created_on).map(&:notes)
      end

      def journals
        @journals ||= JournalsDrop.new @issue.journals.where.not(notes: [nil, ''])
      end

      def tags
        @issue.respond_to?(:tag_list) && @issue.tag_list
      end

      def story_points
        @issue.respond_to?(:story_points) && @issue.story_points
      end

      def color
        @issue.respond_to?(:color) && @issue.color
      end

      def day_in_state
        @issue.respond_to?(:day_in_state) && @issue.day_in_state
      end

      def checklists
        @issue.respond_to?(:checklists) && @issue.checklists.map do |item|
          { 'id_done' => item.is_done, 'subject' => item.subject, 'is_section' => item.is_section }
        end
      end

      def helpdesk_ticket
        return nil unless defined?(::HelpdeskTicketDrop)

        @helpdesk_ticket ||= HelpdeskTicketDrop.new(@issue)
      end

      def custom_field_values
        @issue.custom_field_values
      end
    end

    class JournalsDrop < ::Liquid::Drop
      def initialize(journals)
        @journals = journals
      end

      def all
        @all ||=
          @journals.map do |journal|
            JournalDrop.new journal
          end
      end

      def visible
        @visible ||= @all.select(&:visible?)
      end

      def each(&block)
        all.each(&block)
      end

      def size
        @journals.size
      end
    end

    class JournalDrop < ::Liquid::Drop
      delegate :id, :notes, :created_on, :private_notes, to: :@journal, allow_nil: true

      def initialize(journal)
        @journal = journal
      end

      def user
        @user ||= UserDrop.new(@journal.user)
      end

      def issue
        @issue ||= IssueDrop.new @journal.issue if @journal.issue
      end

      def attachments
        @attachments ||= @journal.attachments.map { |attachment| AttachmentDrop.new(attachment) }
      end
    end
  end
end
