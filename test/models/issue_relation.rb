require_relative 'issue'

class IssueRelation < ActiveRecord::Base
  belongs_to :issue_from, :class_name => 'Issue'
  belongs_to :issue_to, :class_name => 'Issue'

  def other_issue(issue)
    (self.issue_from_id == issue.id) ? issue_to : issue_from
  end
end
