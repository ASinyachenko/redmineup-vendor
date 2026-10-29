module Redmineup
  module Liquid
    class VersionDrop < ::Liquid::Drop
      delegate  :id,
                :name,
                :description,
                :effective_date,
                :due_date,
                :wiki_page_title,
                :status,
                :sharing,
                :default_project_version,
                :start_date,
                :estimated_hours,
                :spent_hours,
                :closed?,
                :open?,
                :completed?,
                :completed_percent,
                :closed_percent,
                :overdue?,
                :issues_count,
                :open_issues_count,
                :closed_issues_count,
                :visible_fixed_issues,
                :wiki_page,
                :to_s_with_project,
                :shared?,
                :deletable?,
                :to_s,
                to: :@version

      def initialize(version)
        @version = version
      end
    end
  end
end
